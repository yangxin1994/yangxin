class JobsController < ApplicationController

	def email_job
		user = User.find_by_email(params[:email])
		render_json_e(ErrorEnum::USER_NOT_EXIST) and return if user.nil?
		case params[:email_type]
		when 'welcome'
			UserMailer.welcome_email(user).deliver
		when 'activate'
			UserMailer.activate_email(user).deliver
		when 'password'
			UserMailer.password_email(user).deliver
		end
		render_json_s(true) and return
	end

	def result_job
		case params[:result_type]
		when "data_list"
			# get the survey instance
			survey = Survey.find_by_id(params[:survey_id])
			render_json_e(ErrorEnum::SURVEY_NOT_EXIST) and return if survey.nil?
			# find answers set
			answers = survey.get_answers(params[:filter_index].to_i,
										params[:include_screened_answer].to_s == "true",
										params[:task_id])
			# generate the result_key
			result_key = DataListResult.generate_result_key(answers)
			# create data list result
			data_list_result = DataListResult.create(:result_key => result_key, :task_id => params[:task_id])
			# analyze and save the answer info
			retval = data_list_result.analyze_answer_info(answers, params[:task_id])
			render_json_auto(retval) and return
		when "analysis"
			# get the survey instance
			survey = Survey.find_by_id(params[:survey_id])
			render_json_e(ErrorEnum::SURVEY_NOT_EXIST) and return if survey.nil?
			# find answers set
			answers = survey.get_answers(params[:filter_index].to_i,
										params[:include_screened_answer].to_s == "true",
										params[:task_id])
			# generate the result_key
			result_key = AnalysisResult.generate_result_key(answers)
			# create analysis result
			analysis_result = AnalysisResult.create(:result_key => result_key, :task_id => params[:task_id])
			# analyze and save the analysis result
			retval = analysis_result.analysis(answers, params[:task_id])
			render_json_auto(retval) and return
		when "report"
			survey = Survey.find_by_id(params[:survey_id])
			render_json_e(ErrorEnum::SURVEY_NOT_EXIST) and return if survey.nil?
			# find answers set
			answers = survey.get_answers(params[:filter_index].to_i,
										params[:include_screened_answer].to_s == "true",
										params[:task_id])
			report_mockup = ReportMockup.find_by_id(params[:report_mockup_id])
			# generate result key
			result_key = ReportResult.generate_result_key(answers, report_mockup, report_style, report_type)
			# create new result record
			report_result = ReportResult.create(:result_key => result_key, :task_id => params["task_id"])
			# transform the answers
			answers_transform = {}
			answers.each_with_index do |answer, index|
				# re-organize answers
				answer.answer_content.each do |q_id, question_answer|
					answers_transform[q_id] ||= []
					answers_transform[q_id] << question_answer if !question_answer.blank?
				end
			end
			# generate the report
			retval = report_result.generate_report(report_mockup, report_type, report_style, answers_transform)
			render_json_auto(retval) and return
		when "to_spss"
			
		when "to_excel"
			
		end
	end
end
