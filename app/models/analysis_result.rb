# encoding: utf-8
require 'error_enum'
require 'array'
require 'tool'
require 'digest/md5'
class AnalysisResult < Result
	include Mongoid::Document
	include Mongoid::Timestamps

	field :duration_result, :type => Float
	field :time_result, :type => Hash
	field :region_result, :type => Hash
	field :channel_result, :type => Hash
	field :answers_result, :type => Hash

	belongs_to :survey

	def self.find_or_create_by_filter_index(survey, filter_index, include_screened_answer)
		answers = self.answers(survey, filter_index, include_screened_answer)
		result_key = self.generate_result_key(answers)
		analysis_result = self.find_by_result_key(result_key)
		if analyze_result.nil?
			analysis_result = AnalysisResult.new(:result_key => result_key)
			analysis_result.analyze_duration(answers)
			analysis_result.analyze_time(answers)
			analysis_result.analyze_region(answers)
			analysis_result.analyze_channel(answers)
			analysis_result.analyze_answers(answers)
			analysis_result.finished = true
			analysis_result.save
		end
		return analysis_result
	end

	def analyze_region(answers)
		# get data
		region_ary = answers.map { |a| a.region }
		# make stats
		self.address_result = Address.province_hash.merge(Address.city_hash)
		region_ary.each do |region|
			self.address_result[region] = self.address_result[region] + 1 if !self.address_result[region].nil?
		end
	end

	def analyze_channel(answers)
		# get data
		channel_ary = answers.map { |a| a.channel }
		# make stats
		self.channel_result = {}
		channel_ary.each do |channel|
			self.channel_result[channel] = 0 if self.channel_result[channel].nil?
			self.channel_result[channel] = self.channel_result[channel] + 1
		end
	end

	def analyze_time(answers)
		# get data
		time_ary = answers.map { |a| a.is_finish ? a.finished_at : a.rejected_at }
		time_ary.sort!
		# get segment parameters, 5 segments by default
		segments = segmentation(5, time_ary[0], time_ary[-1])

		# make stats of segment results
		self.time_result["histogram"] = [segments, get_continuous_histogram(time_ary, segments)]
	end

	def analyze_duration(answers)
		# get data
		duration_ary = answers.map { |a| a.finished_at - a.created_at.to_i }
		duration_ary.sort!
		# get segment parameters, 5 segments by default
		segments = segmentation(5, duration_ary[0], duration_ary[-1])

		# make stats of segment results
		self.duration_result["histogram"] = [segments, get_continuous_histogram(duration_ary, segments)]

		# make other stats
		self.duration_result["mean"] = duration_ary.mean
	end


	def analyze_answers(answers)
		self.answer_result["total_answer_number"] = answers.length

		answers_transform = {}
		survey.pages.each do |page|
			page["questions"].each do |q_id|
				answers_transform[q_id] = []
			end
		end
		survey.quota_template_question_page.each do |q_id|
			answers_transform[q_id] = []
		end

		answers.each do |answer|
			all_answer_content = answer.answer_content.mrege(answer.template_answer_content)
			all_answer_content.each do |q_id, question_answer|
				answers_transform[q_id] << question_answer if !question_answer.blank?
			end
		end

		answers_transform.each do |q_id, question_answer_ary|
			self.answer_result[q_id] = [question_answer_ary.length, analyze_one_question_answers(q_id, question_answer_ary)]
		end
	end

	def analyze_one_question_answers(q_id, answer_ary)
		question = Question.find_by_id(q_id)
		case question.question_type
		when QuestionTypeEnum::CHOICE_QUESTION
			return analyze_choice(question.issue, answer_ary)
		when QuestionTypeEnum::MATRIX_CHOICE_QUESTION
			return analyze_matrix_choice(question.issue, answer_ary)
		when QuestionTypeEnum::NUMBER_BLANK_QUESTION
			return analyze_number_blank(question.issue, answer_ary)
		when QuestionTypeEnum::TIME_BLANK_QUESTION
			return analyze_time_blank(question.issue, answer_ary)
		when QuestionTypeEnum::ADDRESS_BLANK_QUESTION
			return analyze_address_blank(question.issue, answer_ary)
		when QuestionTypeEnum::BLANK_QUESTION
			return analyze_blank(question.issue, answer_ary)
		when QuestionTypeEnum::MATRIX_BLANK_QUESTION
			return analyze_matrix_blank(question.issue, answer_ary)
		when QuestionTypeEnum::TABLE_QUESTION
			return analyze_table(question.issue, answer_ary)
		when QuestionTypeEnum::CONST_SUM_QUESTION
			return analyze_const_sum(question.issue, answer_ary)
		when QuestionTypeEnum::SORT_QUESTION
			return analyze_sort(question.issue, answer_ary)
		when QuestionTypeEnum::RANK_QUESTION
			return analyze_rank(question.issue, answer_ary)
		end
	end

	def analyze_choice(issue, answer_ary)
		input_ids = issue["items"].map { |e| e["id"] }
		input_ids << issue["other_item"]["id"] if !issue["other_item"].nil? && issue["other_item"]["has_other_item"]
		result = {}
		input_ids.each { |input_id| result[input_id] = 0 }
		answer_ary.each do |answer|
			answer["selection"].each do |input_id|
				result[input_id] = result[input_id] + 1 if !result[input_id].nil?
			end
		end
		return result
	end

	def analyze_matrix_choice(issue, answer_ary)
		input_ids = issue["choices"].map { |e| e["id"] }
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

	def analyze_number_blank(issue, answer_ary)
		result = {}		
		answer_ary.map! { |answer| answer.to_f }
		answer_ary.sort!
		result["mean"] = answer_ary.mean

		# segmentation, 5 segments by default
		segments = segmentation(5, answer_ary[0], answer_ary[-1])

		# make stats of segment results
		result["histogram"] = [segments, get_continuous_histogram(answer_ary, segments)]

		return result
	end

	def analyze_time_blank(issue, answer_ary)
		result = {}
		answer_ary = answer_ary.map! do |answer|
			Time.mktime(answer[0], answer[1], answer[2], answer[3], answer[4], answer[5]).to_i
		end
		answer_ary.sort!
		result["mean"] = answer_ary.mean

		# segmentation, 5 segments by default
		segments = segmentation(5, answer_ary[0], answer_ary[-1])

		# make stats of segment results
		result["histogram"] = get_continuous_histogram(answer_ary, segments)

		return result
	end

	def analyze_address_blank(issue, answer_ary)
		result = {}
		if issue["format"].to_i & 4
			# city is required
			result = Address.province_hash
			answer_ary = answer_ary.map! do |answer|
				answer[1].to_i
			end
		else
			# only province is required
			result = Address.city_hash
			answer_ary = answer_ary.map! do |answer|
				answer[0].to_i
			end
		end
		result = get_discrete_histogram(answer_ary, result)

		return result
	end

	def analyze_blank(issue, answer_ary)
		result = {}
		issue["items"].each_with_index do |input, input_index|
			case input["data_type"]
			when "Number"
				result[input["id"]] = analyze_number_blank(input["properties"], answer_ary.map { |e| e[input_index] })
			when "Address"
				result[input["id"]] = analyze_address_blank(input["properties"], answer_ary.map { |e| e[input_index] })
			when "Time"
				result[input["id"]] = analyze_time_blank(input["properties"], answer_ary.map { |e| e[input_index] })
			end
		end
		return result
	end

	def analyze_matrix_blank(issue, answer_ary)
		result = {}

		issue["rows"].each_with_index do |row, row_index|
			row_id = row["id"]
			issue["items"].each_with_index do |input, input_index|
				input_id = input["id"]
				case input["data_type"]
				when "Number"
					result["#{row_id}-#{input_id}"] = analyze_number_blank(input["properties"], answer_ary.map { |e| e[row_index][input_index] })
				when "Address"
					result["#{row_id}-#{input_id}"] = analyze_address_blank(input["properties"], answer_ary.map { |e| e[row_index][input_index] })
				when "Time"
					result["#{row_id}-#{input_id}"] = analyze_time_blank(input["properties"], answer_ary.map { |e| e[row_index][input_index] })
				end
			end
		end
		return result
	end

	def analyze_table(issue, answer_ary)
		result = {}
		flatten_answer_ary = answer_ary.flatten(1)
		issue["items"].each_with_index do |input, input_index|
			case input["data_type"]
			when "Number"
				result[input["id"]] = analyze_number_blank(input["properties"], flatten_answer_ary.map { |e| e[input_index] })
			when "Address"
				result[input["id"]] = analyze_address_blank(input["properties"], flatten_answer_ary.map { |e| e[input_index] })
			when "Time"
				result[input["id"]] = analyze_time_blank(input["properties"], flatten_answer_ary.map { |e| e[input_index] })
			end
		end
		return result
	end

	def analyze_const_sum(issue, answer_ary)
		input_ids = issue["items"].map { |e| e["id"] }
		input_ids << issue["other_item"]["id"] if !issue["other_item"].nil? && issue["other_item"]["has_other_item"]
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

	def analyze_sort(issue, answer_ary)
		input_ids = issue["items"].map { |e| e["id"] }
		input_ids << issue["other_item"]["id"] if !issue["other_item"].nil? && issue["other_item"]["has_other_item"]
		
		input_number = input_ids.length
		result = {}
		input_ids.each do |input_id|
			result[input_id] = Array(input_number, 0)
		end

		answer_ary.each do |answer|
			answer["sort_result"].each_with_index do |input_id, sort_index|
				result[input_id][sort_index] = result[input_id][sort_index] + 1 if sort_index < input_number
			end
		end

		return result
	end

	def analyze_rank(issue, answer_ary)
		input_ids = issue["items"].map { |e| e["id"] }
		input_ids << issue["other_item"]["id"] if !issue["other_item"].nil? && issue["other_item"]["has_other_item"]
		scores = {}
		input_ids.each { |input_id| scores[input_id] = [] }
		
		answer_ary.each do |answer|
			answer.each do |input_id, value|
				scores[input_id] << value if !scores[input_id].nil? && value.to_i != -1
			end
		end

		result = {}
		scores.each do |key, score_ary|
			result[key] = []
			result[key] << score_ary.length
			result[key] << (score_ary.blank? ? -1 : score_ary.mean)
		end

		return result
	end

	def segmentation(segment_number, min_value, max_value)
		interval = (max_value - min_value) * 1.0 / segment_num
		segments = []
		1.upto(segment_num - 1) do |i|
			segments << min_value + i * interval
		end
		segments << max_value
		return segments
	end

	def get_continuous_histogram(data, segments)
		histogram = Array(segments.length, 0)
		segment_index = 0
		data.each do |value|
			if value > segments[segment_index]
				segment_index = segment_index + 1
				redo
			end
			segments_result[segment_index] = segments_result[segment_index] + 1
		end
		return histogram
	end

	def get_discrete_histogram(data, segments)
		data.each do |value|
			segments[value] = segments[value] + 1 if !segments[value].nil?
		end
		return segments
	end
end
