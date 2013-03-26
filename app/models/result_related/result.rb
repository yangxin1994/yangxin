require 'error_enum'
require 'array'
require 'tool'
require 'connect_dot_net'
require 'quill_common'
class Result
	include Mongoid::Document
	include Mongoid::Timestamps

	field :task_id, :type => String
	field :result_key, :type => String
	field :status, :type => Integer, default: 0
	field :ref_result_id, :type => String
	field :error_code, :type => String
	field :error_message, :type => String

	belongs_to :survey

	index({ task_id: 1 }, { background: true } )
	index({ result_key: 1, ref_result_id: 1 }, { background: true } )
	index({ result_key: 1, ref_result_id: 1, status: 1 }, { background: true } )

	def self.find_by_result_id(result_id)
		return Result.where(:_id => result_id)[0]
	end

	def self.find_by_task_id(task_id)
		result = Result.where(:task_id => task_id).first
		return nil if result.nil?
		return Result.where(:result_key => result.result_key, :ref_result_id => nil).first
	end

	def self.find_by_result_key(result_key)
		return Result.where(:result_key => result_key, :ref_result_id => nil, :status.gt => -1).first
	end

	def self.get_file_uri(task_id)
		result = self.find_by_task_id(task_id)
		return ErrorEnum::RESULT_NOT_EXIST if result.nil?
		return result.file_uri
	end

	def self.job_progress(task_id)
		result = Result.find_by_task_id(task_id)
		# if the result does not exist return 0
		return 0 if result.nil?
		# the task is finished or there is error, return
		return result.status if result && result.status == 1 || result.status == -1

		# the task has not been finished, check the progress
		task_id = result.task_id
		task = Task.find_by_id(task_id)
		if task.nil?
			result.status = -1
			result.save
			return ErrorEnum::TASK_NOT_EXIST
		end
		if Time.now.to_i - task.updated_at.to_i > 600
			result.status = -1
			result.save
			return ErrorEnum::TASK_TIMEOUT
		end
		progress = task.progress

		# calculate the status
		case task.task_type
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
			s1 = progress["data_conversion_progress"].to_f
			if s1 < 1
				s = s1 * 0.6
			else
				r = ConnectDotNet.get_data("/GetProgress.aspx?job_id=#{task_id}") do
					{}
				end
				s2 = r.body.to_f
				if s2 != progress["export_spss_progress"].to_f
					progress["export_spss_progress"] = s2
				end
				s = s1 * 0.6 + s2 * 0.4
			end
		when "to_excel"
			s1 = progress["data_conversion_progress"].to_f
			if s1 < 1
				s = s1 * 0.6
			else
				r = ConnectDotNet.get_data("/GetProgress.aspx?job_id=#{task_id}") do
					{}
				end
				s2 = r.body.to_f
				if s2 != progress["export_excel_progress"].to_f
					progress["export_excel_progress"] = s2
				end
				s = s1 * 0.6 + s2 * 0.4
			end
		when "report"
			s1 = progress["data_conversion_progress"].to_f
			if s1 < 1
				s = s1 * 0.3
			else
				r = ConnectDotNet.get_data("/GetProgress.aspx?job_id=#{task_id}") do
					{}
				end
				s2 = r.body.to_f
				if s2 != progress["export_report_progress"].to_f
					progress["export_report_progress"] = s2
				end
				s = s1 * 0.3 + s2 * 0.7
			end
		end
		task.save
		# the job has not been finished, the progress cannot be greater than 0.99
		return [s, 0.99].min
	end


	def analyze_choice(issue, answer_ary, opt={})
		items_com = opt[:items_com] || []
		input_ids = issue["items"].map { |e| e["id"] }
		input_ids << issue["other_item"]["id"] if !issue["other_item"].nil? && issue["other_item"]["has_other_item"]
		if !items_com.blank?
			# combine items
			items_com.each do |com|
				com.each { |input_id| input_ids.delete(input_id) }
				input_ids << com.join(',')
			end
		end
		input_ids.map! { |e| e.to_s }
		result = {}
		input_ids.each { |input_id| result[input_id] = 0 }
		answer_ary.each do |answer|
			answer["selection"].each do |input_id|
				result.each_key do |k|
					if k.split(',').include?(input_id.to_s)
						result[k] = result[k] + 1
						break
					end
				end
			end
		end
		return result
	end

	def analyze_matrix_choice(issue, answer_ary, opt={})
		items_com = opt[:items_com] || []
		input_ids = issue["items"].map { |e| e["id"] }
		if !items_com.blank?
			# combine items
			items_com.each do |com|
				com.each { |input_id| input_ids.delete(input_id) }
				input_ids << com.join(',')
			end
		end
		input_ids.map! { |e| e.to_s }
		result = {}
		issue["rows"].each do |row|
			input_ids.each do |input_id|
				result["#{row["id"]}-#{input_id}"] = 0
			end
		end
		row_ids = issue["rows"].map { |e| e["id"].to_s }
		answer_ary.each do |answer|
			answer.each do |row_id, row_answer|
				row_id = row_id.to_s
				next if !row_ids.include?(row_id)
				row_answer.each do |input_id|
					result.each_key do |k|
						k_row_id = k.split('-')[0]
						k_input_ids = k.split('-')[1].split(',')
						if k_row_id == row_id && k_input_ids.include?(input_id.to_s)
							result[k] = result[k] + 1
							break
						end
					end
				end
			end
		end
		return result
	end

	def analyze_text_blank(issue, answer_ary, opt={})
		return answer_ary
	end

	def analyze_url_blank(issue, answer_ary, opt={})
		return answer_ary
	end

	def analyze_phone_blank(issue, answer_ary, opt={})
		return answer_ary
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
		result.each do |key, value|
			result[key] = [value,
						QuillCommon::AddressUtility.find_province_city_town_by_code(key),
						QuillCommon::AddressUtility.find_latlng_by_region_code(key)]
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
		items_com = opt[:items_com] || []
		input_ids = issue["items"].map { |e| e["id"] }
		input_ids << issue["other_item"]["id"] if !issue["other_item"].nil? && issue["other_item"]["has_other_item"]
		if !items_com.blank?
			# combine items
			items_com.each do |com|
				com.each { |input_id| input_ids.delete(input_id) }
				input_ids << com.join(',')
			end
		end
		input_ids.map! { |e| e.to_s }
		weights = {}
		input_ids.each { |input_id| weights[input_id] = [] }

		answer_ary.each do |answer|
			answer.each do |input_id, value|
				weights.each_key do |k|
					if k.split(',').include?(input_id)
						weights[k] << value.to_f
						break
					end
				end
			end
		end

		result = {}
		weights.each do |key, weight_ary|
			result[key] = weight_ary.mean
		end

		return result
	end

	def analyze_sort(issue, answer_ary, opt={})
		items_com = opt[:items_com] || []
		input_ids = issue["items"].map { |e| e["id"] }
		input_ids << issue["other_item"]["id"] if !issue["other_item"].nil? && issue["other_item"]["has_other_item"]
		if !items_com.blank?
			# combine items
			items_com.each do |com|
				com.each { |input_id| input_ids.delete(input_id) }
				input_ids << com.join(',')
			end
		end
		input_ids.map! { |e| e.to_s }
		
		input_number = input_ids.length
		result = {}
		input_ids.each do |input_id|
			result[input_id] = Array.new(input_number, 0)
		end
	
		answer_ary.each do |answer|
			answer["sort_result"].each_with_index do |input_id, sort_index|
				result.each_key do |k|
					if k.split(',').include?(input_id)
						result[k][sort_index] = result[k][sort_index] + 1 if sort_index < input_number
						break
					end
				end
			end
		end
	
		return result
	end

	def analyze_scale(issue, answer_ary, opt={})
		items_com = opt[:items_com] || []
		input_ids = issue["items"].map { |e| e["id"] }
		if !items_com.blank?
			# combine items
			items_com.each do |com|
				com.each { |input_id| input_ids.delete(input_id) }
				input_ids << com.join(',')
			end
		end
		input_ids.map! { |e| e.to_s }

		scores = {}
		input_ids.each { |input_id| scores[input_id] = [] }
		
		answer_ary.each do |answer|
			answer.each do |input_id, value|
				# value is 0-based, should be converted to score-based
				input_ids.each do |k|
					if k.split(',').include?(input_id)
						scores[k] << value + 1 if value.to_i != -1
						break
					end
				end
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