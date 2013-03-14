class ReportWorker
	include Sidekiq::Worker
	sidekiq_options :retry => false, :queue => "oopsdata_#{Rails.env}".to_sym

	def perform(survey_id, analysis_task_id, report_mockup_id, report_type, report_style, task_id)
		survey = Survey.find_by_id(survey_id)
		return false if survey.nil?
		data_list = AnalysisResult.get_data_list(analysis_task_id)
		return false if data_list == ErrorEnum::RESULT_NOT_EXIST

		answer_info = data_list[:answer_info] || []
		answers = answer_info.map { |e| Answer.find_by_id e["_id"] }
			
		if report_mockup_id.blank?
			report_mockup = ReportMockup.default_report_mockup(survey)
		else
			report_mockup = ReportMockup.find_by_id(report_mockup_id)
		end
		# generate result key
		result_key = ReportResult.generate_result_key(survey.last_update_time,
			answers,
			report_mockup,
			report_type,
			report_style)

		existing_report_result = ReportResult.find_by_result_key(result_key)
		if existing_report_result.nil?
			# create new result record
			report_result = ReportResult.create(:result_key => result_key,
												:task_id => task_id)
		else
			report_result = ReportResult.create(:result_key => result_key,
												:task_id => task_id,
												:ref_result_id => existing_report_result._id)
			return true
		end

		survey.report_results << report_result
		# transform the answers
		answers_transform = {}
		answers.each_with_index do |answer, index|
			# re-organize answers
			answer.answer_content.each do |q_id, question_answer|
				answers_transform[q_id] ||= []
				answers_transform[q_id] << question_answer
			end
		end
		# generate the report
		report_result.generate_report(report_mockup,
			report_type,
			report_style,
			answers_transform)
		return true
	end
end
