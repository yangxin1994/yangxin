require 'error_enum'
require 'array'
require 'tool'
require 'digest/md5'
require 'quill_common'
class AnalysisResult < Result
	include Mongoid::Document
	include Mongoid::Timestamps

	field :tot_answer_number, :type => Integer, default: 0
	field :screened_answer_number, :type => Integer, default: 0
	field :ongoing_answer_number, :type => Integer, default: 0
	field :wait_for_review_answer_number, :type => Integer, default: 0
	field :answer_info, :type => Array, default: []
	field :duration_mean, :type => Float, default: 0
	field :time_result, :type => Hash, default: {}
	field :region_result, :type => Hash, default: {}
	field :channel_result, :type => Hash, default: {}
	field :referrer_result, :type => Array, default: []
	field :answers_result, :type => Hash, default: {}
	field :latlng_array, :type => Array, default: []

	belongs_to :survey

	def self.generate_result_key(last_update_time, answers, tot_answer_number, screened_answer_number, ongoing_answer_number, wait_for_review_answer_number)
		answer_ids = answers.map { |e| e._id.to_s }
		result_key = Digest::MD5.hexdigest("analysis-#{answer_ids.to_s}-#{tot_answer_number}-#{screened_answer_number}-#{ongoing_answer_number}-#{wait_for_review_answer_number}")
		return result_key
	end


	def analysis(answers, task_id = nil)
		region_result = QuillCommon::AddressUtility.province_hash.merge(QuillCommon::AddressUtility.city_hash).merge(QuillCommon::AddressUtility.county_hash)
		referrer_result = {}
		channel_result = {}
		duration_mean = []
		finish_time = []
		answers_transform = {}
		if answers.length == 0
			if !task_id.nil?
				Task.set_progress(task_id, "analyze_answer_progress", 1.0)
				Task.set_progress(task_id, "answer_info_progress", 1.0)
			end
			self.status = 1
			return self.save
		end

		# get the answer info
		answer_info = []
		answers_length = answers.length
		last_time = Time.now.to_i
		answers.each_with_index do |a, index|
			info = {}
			info["_id"] = a._id.to_s
			info["email"] = a.user.nil? ? "" : a.user.email.to_s
			info["full_name"] = a.user.nil? ? "" : a.user.full_name.to_s
			info["answer_time"] = a.created_at.to_i
			info["duration"] = (!a.finished_at.nil? && !a.created_at.nil?) ? a.finished_at - a.created_at.to_i : nil
			info["region"] = a.region
			answer_info << info
			if Time.now.to_i != last_time
				Task.set_progress(task_id, "answer_info_progress", (index + 1).to_f / answers_length) if !task_id.nil?
				last_time = Time.now.to_i
			end
		end
		Task.set_progress(task_id, "answer_info_progress", 1.0) if !task_id.nil?
		self.answer_info = answer_info
		
		# get the analysis result
		answers.each_with_index do |answer, index|
			# analyze region
			region = answer.region.to_s
			region_result[region]["count"] = region_result[region]["count"] + 1 if !region_result[region].nil?

			# analyze referrer domain
			referrer = answer.referrer
			if !referrer.blank?
				referrer_result[referrer] ||= 0
				referrer_result[referrer] += 1
			end
			
			# analyze channel
			channel = answer.channel.to_s
			channel_result[channel] ||= 0
			channel_result[channel] = channel_result[channel] + 1
			
			# analyze duration
			duration_mean << answer.finished_at - answer.created_at.to_i if answer.finished_at && answer.created_at
			# analyze time
			finish_time << answer.finished_at if answer.finished_at
			# re-organize answers
			answer.answer_content.each do |q_id, question_answer|
				answers_transform[q_id] ||= []
				answers_transform[q_id] << question_answer if !question_answer.blank?
			end
			if Time.now.to_i != last_time
				Task.set_progress(task_id, "analyze_answer_progress", 0.5 * (index + 1) / answers.length) if !task_id.nil?
				last_time = Time.now.to_i
			end
		end
		Task.set_progress(task_id, "analyze_answer_progress", 0.5) if !task_id.nil?
		region_result.select! { |k,v| v["count"] != 0 }
		region_result.each do |key, value|
			region_result[key] = [value, QuillCommon::AddressUtility.find_province_city_town_by_code(key)]
		end
		channel_result.select! { |k,v| v != 0 }
		
		# calculate the mean of duration
		duration_mean = duration_mean.mean

		# make stats of the finish time
		min_finish_time = finish_time.min
		# min_finish_date = Time.at(min_finish_time).to_date
		# start_day = [min_finish_date.year, min_finish_date.month, min_finish_date.day]
		start_day = min_finish_time
		day_number = (finish_time.max / 86400 - min_finish_time / 86400) + 1
		time_histogram = Array.new(day_number, 0)
		finish_time.each do |t|
			time_histogram[t / 86400 - min_finish_time / 86400] = time_histogram[t / 86400 - min_finish_time / 86400] + 1
		end
		time_result = {"start_day" => start_day, "time_histogram" => time_histogram}
		Task.set_progress(task_id, "analyze_answer_progress", 0.6) if !task_id.nil?

		# make stats for the answers
		aanswers_result = {}
		i = 0
		answers_transform.each do |q_id, question_answer_ary|
			i = i + 1
			question = Question.find_by_id(q_id)
			next if question.nil?
			aanswers_result[q_id] = [question_answer_ary.length, analyze_one_question_answers(question, question_answer_ary)]
			if Time.now.to_i != last_time
				Task.set_progress(task_id, "analyze_answer_progress", 0.6 + 0.4 * i / answers_transform.length ) if !task_id.nil?
				last_time = Time.now.to_i
			end
		end
		Task.set_progress(task_id, "analyze_answer_progress", 1.0 ) if !task_id.nil?

		# make stats of latitude and logitute data
		latlng_array = []
		answers.each do |a|
			if !a.longitude.blank? && !a.latitude.blank?
				latlng_array << {"lat"=>a.latitude, "lng"=>a.longitude}
			else
				latlng_array << QuillCommon::AddressUtility.find_province_city_town_by_code(a.region)
			end
		end
		self.latlng_array = latlng_array

		# update analysis result
		self.region_result = region_result
		referrer_result_array = []
		referrer_result.each do |k,v|
			referrer_result_array << [k,v]
		end
		self.referrer_result = referrer_result_array
		self.channel_result = channel_result
		self.duration_mean = duration_mean
		self.time_result = time_result
		self.answers_result = aanswers_result
		self.status = 1
		self.save
	end

	def analyze_one_question_answers(question, answer_ary)
		case question.question_type
		when QuestionTypeEnum::CHOICE_QUESTION
			return analyze_choice(question.issue, answer_ary)
		when QuestionTypeEnum::MATRIX_CHOICE_QUESTION
			return analyze_matrix_choice(question.issue, answer_ary)
		when QuestionTypeEnum::TEXT_BLANK_QUESTION
			return analyze_text_blank(question.issue, answer_ary)
		when QuestionTypeEnum::NUMBER_BLANK_QUESTION
			return analyze_number_blank(question.issue, answer_ary)
		when QuestionTypeEnum::TIME_BLANK_QUESTION
			return analyze_time_blank(question.issue, answer_ary)
		when QuestionTypeEnum::EMAIL_BLANK_QUESTION
			return analyze_email_blank(question.issue, answer_ary)
		when QuestionTypeEnum::ADDRESS_BLANK_QUESTION
			return analyze_address_blank(question.issue, answer_ary)
		when QuestionTypeEnum::URL_BLANK_QUESTION
			return analyze_url_blank(question.issue, answer_ary)
		when QuestionTypeEnum::PHONE_BLANK_QUESTION
			return analyze_phone_blank(question.issue, answer_ary)
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
		when QuestionTypeEnum::SCALE_QUESTION
			return analyze_scale(question.issue, answer_ary)
		end
	end

	def self.get_data_list(task_id)
		# analysis_result = self.where(:task_id => task_id)[0]
		analysis_result = self.find_by_task_id(task_id)
		return ErrorEnum::RESULT_NOT_EXIST if analysis_result.nil?
		return {:result_key => analysis_result.result_key,
				:answer_info => analysis_result.answer_info}
	end

	def self.get_stats(task_id)
		# analysis_result = self.where(:task_id => task_id)[0]
		analysis_result = self.find_by_task_id(task_id)
		return ErrorEnum::RESULT_NOT_EXIST if analysis_result.nil?
		return {:tot_answer_number => analysis_result.tot_answer_number,
				:screened_answer_number => analysis_result.screened_answer_number,
				:ongoing_answer_number => analysis_result.ongoing_answer_number,
				:wait_for_review_answer_number => analysis_result.wait_for_review_answer_number,
				:duration_mean => analysis_result.duration_mean,
				:time_result => analysis_result.time_result,
				:region_result => analysis_result.region_result,
				:channel_result => analysis_result.channel_result}
	end

	def self.get_analysis_result(task_id, page_index)
		# analysis_result = self.where(:task_id => task_id)[0]
		analysis_result = self.find_by_task_id(task_id)
		return ErrorEnum::RESULT_NOT_EXIST if analysis_result.nil?
		page = analysis_result.survey.pages[page_index]
		return ErrorEnum::OVERFLOW if page.nil?
		return analysis_result.answers_result.select { |e, v| page["questions"].include?(e) }
	end
end
