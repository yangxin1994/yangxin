require 'result_job'
module Jobs

	class ReportJob < ResultJob

		@queue = :result_job

		def perform
			# set the type of the job
			set_status({"result_type" => "report"})

			# get parameters
			filter_index = options["filter_index"].to_i
			include_screened_answer = options["include_screened_answer"].to_s == "true"
			report_mockup_id = options["report_mockup_id"].to_s
			report_mockup = ReportMockup.find_by_id(report_mockup_id)
			report_style = options["report_style"].to_i
			report_type = options["report_type"].to_s

			# get answers set by filter
			answers = ResultJob.answers(survey_id, filter_index, include_screened_answer)

			# generate result key
			result_key = sef.generate_result_key(answers, report_mockup, report_style, report_type)

			# judge whether the result_key already exists
			result = DataListResult.find_by_result_key(result_key)
			#create new result record
			if !result.nil?
				report_result = DataListResult.create(:result_key => result_key, :job_id => status["uuid"], :ref_result_id => result._id)
				set_status({"ref_job_id" => result.job_id})
				return
			else
				report_result = DataListResult.create(:result_key => result_key, :job_id => status["uuid"])
			end

			analysis_results = []
			# analyze the result based on the report mockup
			report_mockup.components.each do |component|
				if component["component_type"] == 0
					# this is a single question analysis
					question_id = component["value"]["id"]
					question = Question.find_by_id(question_id)
					case question.question_type
					when QuestionTypeEnum::CHOICE_QUESTION
						analyze_result = analyze_choice(question.issue, answer_ary)
						# judge whether this is a single choice or multiple choice
						if question.issue["max_choice"] == 1
							# this is a single choice question
							# 1. generate the text for this question
							text_description(analyze_result, question)
						else
							# this is a multiple choice question
						end
					when QuestionTypeEnum::MATRIX_CHOICE_QUESTION
						analyze_result = analyze_matrix_choice(question.issue, answer_ary)
					when QuestionTypeEnum::NUMBER_BLANK_QUESTION
						analyze_result = analyze_number_blank(question.issue, answer_ary)
					when QuestionTypeEnum::TIME_BLANK_QUESTION
						analyze_result = analyze_time_blank(question.issue, answer_ary)
					when QuestionTypeEnum::EMAIL_BLANK_QUESTION
						analyze_result = analyze_email_blank(question.issue, answer_ary)
					when QuestionTypeEnum::ADDRESS_BLANK_QUESTION
						analyze_result = analyze_address_blank(question.issue, answer_ary)
					when QuestionTypeEnum::BLANK_QUESTION
						analyze_result = analyze_blank(question.issue, answer_ary)
					when QuestionTypeEnum::MATRIX_BLANK_QUESTION
						analyze_result = analyze_matrix_blank(question.issue, answer_ary)
					when QuestionTypeEnum::TABLE_QUESTION
						analyze_result = analyze_table(question.issue, answer_ary)
					when QuestionTypeEnum::CONST_SUM_QUESTION
						analyze_result = analyze_const_sum(question.issue, answer_ary)
					when QuestionTypeEnum::SORT_QUESTION
						analyze_result = analyze_sort(question.issue, answer_ary)
					when QuestionTypeEnum::RANK_QUESTION
						analyze_result = analyze_rank(question.issue, answer_ary)
					end
				else
					# this is a cross questions analysis
				end
			end

		end

		def generate_result_key(answers, report_mockup, report_style, report_type)
			answer_ids = answers.map { |e| e._id.to_s }
			result_key = Digest::MD5.hexdigest("report-#{report_mockup.to_json}-#{report_style}-#{report_type}-#{answer_ids.to_s}")
			return result_key
		end

		def generate_text_description(analyze_result, description_type)
			case description_type
			when "single_choice"

			end
		end
	end
end
