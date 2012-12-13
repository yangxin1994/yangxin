require 'error_enum'
require 'array'
require 'tool'
class Result
	include Mongoid::Document
	include Mongoid::Timestamps

	field :task_id, :type => String
	field :result_key, :type => String
	field :status, :type => Integer, default: 0
	field :ref_result_id, :type => String

	belongs_to :survey

	def self.find_by_result_id(result_id)
		return Result.where(:_id => result_id)[0]
	end

	def self.find_by_task_id(task_id)
		result = Result.where(:task_id => task_id).first
		return Result.where(:result_key => result.result_key, :ref_result_id => nil).first
	end

	def self.find_by_result_key(result_key)
		return Result.where(:result_key => result_key, :ref_result_id => nil).first
	end

	def self.find_result_by_task_id(task_id)
		result = Result.where(:task_id => task_id)[0]
		return ErrorEnum::RESULT_NOT_EXIST if result.nil?
		result = result.ref_result_id.nil? ? result : Result.find_by_result_id(result.ref_result_id)
		return ErrorEnum::RESULT_NOT_EXIST if result.nil?

		# based on the result type, return results
		case result._type
		when "AnalysisResult"
			return {"result_key" => result.result_key,
					"answer_info" => result.answer_info,
					"region_result" => result.region_result,
					"time_result" => result.time_result,
					"duration_mean" => result.duration_mean,
					"channel_result" => result.channel_result,
					"answers_result" => result.answers_result}
		when "ReportResult"
			# TODO 返回结果
			return {"file_name" => "FinalReport#{result.task_id}.docx"}
		end
	end

	def self.job_progress(task_id)
		result = Result.find_by_task_id(task_id)
		# the task is finished, return
		return 1 if result && result.status == 1

		# the task has not been finished, chech the progress
		task = TaskClient.get_task(task_id)

		return task if task == ErrorEnum::TASK_NOT_EXIST
		progress = task["progress"]

		# calculate the status
		case task["params"]["result_type"]
		when "analysis"
			# the analysis job consists of three parts
			# the first part is to find the answers by the filter
			s1 = progress["find_answers_progress"].to_f
			# the second part is to get the info of the answers
			s2 = progress["answer_info_progress"].to_f
			# the third part is to analyze data
			s3 = progress["analyze_answer_progress"].to_f
			s = s1 * 0.3 + s2 * 0.3 + s3 * 0.4
		when "to_spss"
			s1 = status["export_answers_progress"]
			if s1 < 1
				s = s1 * 0.6
			else
				r = ConnectDotNet::get_data("/get_progress") { task_id }
				s2 = r["status"]
				s = s1 * 0.6 + s2 * 0.4
			end
		when "to_excel"
			s1 = status["export_answers_progress"]
			if s1 < 1
				s = s1 * 0.6
			else
				r = ConnectDotNet::get_data("/get_progress") { task_id }
				s2 = r["status"]
				s = s1 * 0.6 + s2 * 0.4
			end
		when "report"
			s1 = progress["find_answers_progress"].to_f
			if s1 < 1
				s = s1 * 0.3
			else
				s2 = progress["data_conversion_progress"].to_f
#				if s2 < 2
					s = s1 * 0.3 + s2 * 0.2
#				else
#					s3 = ConnectDotNet::get_data("/get_progress") { task_id }
#					s = s1 * 0.3 + s2 * 0.2 + s3 * 0.5
#				end
			end
		end
		# the job has not been finished, the progress cannot be greater than 0.99
		return [s, 0.99].min
	end


	def analyze_choice(issue, answer_ary, opt={})
		input_ids = issue["items"].map { |e| e["id"] }
		input_ids << issue["other_item"]["id"] if !issue["other_item"].nil? && issue["other_item"]["has_other_item"]
		input_ids.map! { |e| e.to_s }
		result = {}
		input_ids.each { |input_id| result[input_id] = 0 }
		answer_ary.each do |answer|
			answer["selection"].each do |input_id|
				result[input_id.to_s] = result[input_id.to_s] + 1 if !result[input_id.to_s].nil?
			end
		end
		return result
	end

	def analyze_matrix_choice(issue, answer_ary, opt={})
		input_ids = issue["items"].map { |e| e["id"] }
		input_ids.map! { |e| e.to_s }
		result = {}
		issue["rows"].each do |row|
			input_ids.each do |input_id|
				result["#{row["id"]}-#{input_id}"] = 0
			end
		end
			answer_ary.each do |answer|
			answer.each_with_index do |row_answer, row_index|
				row_id = issue["rows"][row_index]["id"]
				row_answer.each do |input_id|
					result["#{row_id}-#{input_id}"] = result["#{row_id}-#{input_id}"] + 1 if !result["#{row_id}-#{input_id}"].nil?
				end
			end
		end
		return result
	end

	def analyze_number_blank(issue, answer_ary, opt={})
		segment = opt[:segment]
		result = {}		
		answer_ary.map! { |answer| answer.to_f }
		answer_ary.sort!
		result["mean"] = answer_ary.mean
		setment = opt[:segment] || []
		if segment.blank?
			segment = [answer_ary[0], (answer_ary[0].to_f + answer_ary[-1].to_f) / 2, answer_ary[-1]]
		end
		if !segment.blank?
			histogram = Array.new(segment.length + 1, 0)
			segment_index = 0
			answer_ary.each do |a|
				if segment_index < segment.length
					while a > segment[segment_index].to_f
						segment_index = segment_index + 1
						break if segment_index >= segment.length
					end
				end
				histogram[segment_index] = histogram[segment_index] + 1
			end
			result["histogram"] = histogram
		end
		result["segment"] = segment
		return result
	end

	def analyze_time_blank(issue, answer_ary, opt={})
		segment = opt[:segment]
		result = {}
		# the raw answers are in the unit of milliseconds
		answer_ary.map! { |e| (e / 1000).round }
		answer_ary.sort!
		result["mean"] = answer_ary.mean
		if segment.blank?
			segment = [answer_ary[0], (answer_ary[0].to_f + answer_ary[-1].to_f) / 2, answer_ary[-1]]
		end
		if !segment.blank?
			histogram = Array.new(segment.length + 1, 0)
			segment_index = 0
			answer_ary.each do |a|
				if segment_index < segment.length
					while a > segment[segment_index]
						segment_index = segment_index + 1
						break if segment_index >= segment.length
					end
				end
				histogram[segment_index] = histogram[segment_index] + 1
			end
			result["histogram"] = histogram
		end
		result["segment"] = segment
		return result
	end

	def analyze_email_blank(issue, answer_ary, opt={})
		result = {}
		answer_ary.each do |email_address|
			domain_name = (email_address.split('@'))[-1]
			domain_name.gsub!(".", "_")
			result[domain_name] = 0 if result[domain_name].nil?
			result[domain_name] = result[domain_name] + 1
		end
		return result
	end

	def analyze_address_blank(issue, answer_ary, opt={})
		result = {}
		answer_ary.each do |value|
			region_code = value["address"]
			result[region_code] = 0 if result[region_code].nil?
			result[region_code] = result[region_code] + 1
		end
		return result
	end

	def analyze_blank(issue, answer_ary, opt={})
		result = {}
		issue["items"].each_with_index do |input, input_index|
			segment = opt[:segment].nil? ? nil : opt[:segment][input["id"].to_s]
			case input["data_type"]
			when "Number"
				result[input["id"].to_s] = analyze_number_blank(input["properties"],
																answer_ary.map { |e| e[input_index] },
																:segment => segment)
			when "Time"
				result[input["id"].to_s] = analyze_time_blank(input["properties"],
															answer_ary.map { |e| e[input_index] },
															:segment => segment)
			when "Address"
				result[input["id"].to_s] = analyze_address_blank(input["properties"], answer_ary.map { |e| e[input_index] })
			when "Email"
				result[input["id"].to_s] = analyze_email_blank(input["properties"], answer_ary.map { |e| e[input_index] })
			end
		end
		return result
	end

	def analyze_const_sum(issue, answer_ary, opt={})
		input_ids = issue["items"].map { |e| e["id"] }
		input_ids << issue["other_item"]["id"] if !issue["other_item"].nil? && issue["other_item"]["has_other_item"]
		input_ids.map! { |e| e.to_s }
		weights = {}
		input_ids.each { |input_id| weights[input_id] = [] }

		answer_ary.each do |answer|
			answer.each do |input_id, value|
				weights[input_id] << value.to_f if !weights[input_id].nil?
			end
		end

		result = {}
		weights.each do |key, weight_ary|
			result[key] = weight_ary.mean
		end

		return result
	end

	def analyze_sort(issue, answer_ary, opt={})
		input_ids = issue["items"].map { |e| e["id"] }
		input_ids << issue["other_item"]["id"] if !issue["other_item"].nil? && issue["other_item"]["has_other_item"]
		input_ids.map! { |e| e.to_s }
		
		input_number = input_ids.length
		result = {}
		input_ids.each do |input_id|
			result[input_id] = Array.new(input_number, 0)
		end
	
		answer_ary.each do |answer|
			answer["sort_result"].each_with_index do |input_id, sort_index|
				result[input_id][sort_index] = result[input_id][sort_index] + 1 if sort_index < input_number
			end
		end
	
		return result
	end

	def analyze_scale(issue, answer_ary, opt={})
		input_ids = issue["items"].map { |e| e["id"] }
		input_ids.map! { |e| e.to_s }

		scores = {}
		input_ids.each { |input_id| scores[input_id] = [] }
		
		answer_ary.each do |answer|
			answer.each do |input_id, value|
				# value is 0-based, should be converted to score-based
				scores[input_id] << value + 1 if !scores[input_id].nil? && value.to_i != -1
			end
		end
	
		result = {}
		scores.each do |key, score_ary|
			result[key] = []
			result[key] << score_ary.length
			result[key] << (score_ary.blank? ? 0 : score_ary.mean)
		end
	
		return result
	end
end