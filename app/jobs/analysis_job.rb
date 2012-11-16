require 'result_job'
require 'array'
module Jobs

	class AnalysisJob < ResultJob

		@queue = :result_job

		def perform
			# set the type of the job
			set_status({"result_type" => "analysis"})

			# get parameters
			filter_index = options["filter_index"].to_i
			include_screened_answer = options["include_screened_answer"].to_s == "true"
			survey_id = options["survey_id"]

			# get answers set by filter
			answers = get_answers(survey_id, filter_index, include_screened_answer)

			# generate result key
			result_key = AnalysisJob.generate_result_key(answers)

			# judge whether the result_key already exists
			result = AnalysisResult.find_by_result_key(result_key)
			#create new result record
			if !result.nil?
				analysis_result = AnalysisResult.create(:result_key => result_key, :job_id => status["uuid"], :ref_result_id => result._id)
				set_status({"ref_job_id" => result.job_id})
				return
			else
				analysis_result = AnalysisResult.create(:result_key => result_key, :job_id => status["uuid"])
			end

			# analyze result
			region_result, channel_result, duration_mean, time_result, answers_result = *analysis(answers)

			# update analysis result
			analysis_result.region_result = region_result
			analysis_result.channel_result = channel_result
			analysis_result.duration_mean = duration_mean
			analysis_result.time_result = time_result
			analysis_result.answers_result = answers_result
			analysis_result.status = 1
			analysis_result.save
		end

		def self.generate_result_key(answers)
			answer_ids = answers.map { |e| e._id.to_s }
			result_key = Digest::MD5.hexdigest("analyze_result-#{answer_ids.to_s}")
			return result_key
		end

		def analysis(answers)
			region_result = Address.province_hash.merge(Address.city_hash)
			channel_result = {}
			duration_mean = []
			finish_time = []
			answers_transform = {}
			
			answers.each_with_index do |answer, index|
				# analyze region
				region = answer.region.to_s
				region_result[region] = region_result[region] + 1 if !region_result[region].nil?
				
				# analyze channel
				channel = answer.channel.to_s
				channel_result[channel] ||= 0
				channel_result[channel] = channel_result[channel] + 1
				
				# analyze duration
				duration_mean << answer.finished_at - answer.created_at.to_i

				# analyze time
				finish_time << answer.finished_at

				# re-organize answers
				answer.answer_content.each do |q_id, question_answer|
					answers_transform[q_id] ||= []
					answers_transform[q_id] << question_answer if !question_answer.blank?
				end

				set_status({"analyze_answer_progress" => 0.5 * (index + 1) * 1.0 / answers.length })
			end

			region_result.select! { |k,v| v != 0 }
			channel_result.select! { |k,v| v != 0 }
			
			# calculate the mean of duration
			duration_mean = duration_mean.mean

			# make stats of the finish time
			# min_finish_time = finish_time.min
			# min_finish_date = Time.at(min_finish_time).to_date
			# start_day = [min_finish_date.year, min_finish_date.month, min_finish_date.day]
			start_day = finish_time.min
			day_number = (finish_time.max / 86400 - min_finish_time / 86400) + 1
			time_histogram = Array.new(day_number, 0)
			finish_time.each do |t|
				time_histogram[t / 86400 - min_finish_time / 86400] = time_histogram[t / 86400 - min_finish_time / 86400] + 1
			end
			time_result = {"start_day" => start_day, "time_histogram" => time_histogram}
			set_status({"analyze_answer_progress" => 0.6 })

			# make stats for the answers
			answers_result = {}
			i = 0
			answers_transform.each do |q_id, question_answer_ary|
				i = i + 1
				question = Question.find_by_id(q_id)
				answers_result[q_id] = [question_answer_ary.length, AnalysisJob.analyze_one_question_answers(question, question_answer_ary)]
				set_status({"analyze_answer_progress" => 0.6 + 0.4 * i / answers_transform.length })
			end

			return [region_result, channel_result, duration_mean, time_result, answers_result]
		end

		def self.analyze_one_question_answers(question, answer_ary)
			case question.question_type
			when QuestionTypeEnum::CHOICE_QUESTION
				return analyze_choice(question.issue, answer_ary)
			when QuestionTypeEnum::MATRIX_CHOICE_QUESTION
				return analyze_matrix_choice(question.issue, answer_ary)
			when QuestionTypeEnum::NUMBER_BLANK_QUESTION
				return analyze_number_blank(question.issue, answer_ary)
			when QuestionTypeEnum::TIME_BLANK_QUESTION
				return analyze_time_blank(question.issue, answer_ary)
			when QuestionTypeEnum::EMAIL_BLANK_QUESTION
				return analyze_email_blank(question.issue, answer_ary)
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
			when QuestionTypeEnum::SCALE_QUESTION
				return analyze_scale(question.issue, answer_ary)
			end
		end
	end
end
