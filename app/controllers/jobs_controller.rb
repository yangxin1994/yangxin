class JobsController < ApplicationController

	def email_job
		user = User.find_by_email(params[:email])
		render_json_e(ErrorEnum::USER_NOT_EXIST) and return if user.nil?
		callback = params[:callback]
		case params[:email_type]
		when 'welcome'
			UserMailer.welcome_email(user, params[:callback]).deliver
		when 'activate'
			UserMailer.activate_email(user, params[:callback]).deliver
		when 'password'
			UserMailer.password_email(user, params[:callback]).deliver
		end
		render_json_s(true) and return
	end

	def quota_job
		# 1. get all samples, excluding those are in the blacklist
		user_ids = User.ids_not_in_blacklist
		# 2. get the remaining number for each survey
		published_survey = Survey.get_published_active_surveys
		email_number_ary = published_survey.map do |e|
			amount = e.remaining_quota_amount
			email_number = amount * 3
		end
		# 3. find out samples for surveys
		surveys_for_user = {}
		published_survey.each do |survey|
			amount = e.remaining_quota_amount
			email_number = amount * 3
			user_ids_answered = survey.get_user_ids_answered
			user_ids_sent = EmailHistory.get_user_ids_sent(s_id)
			user_ids = user_ids - user_ids_answered[s_id] - user_ids_sent[s_id]
			samples_found = user_ids.length > email_number ? user_ids.shuffle[0..rule.email_number-1] : user_ids
			samples_found.each do |u_id|
				surveys_for_user[u_id] ||= []
				surveys_for_user[u_id] << survey._id
			end
		end
		# 4. send emails to the samples found
		surveys_for_user.each do |u_id, s_id_ary|
			UserMailer.survey_email(u_id, s_id_ary).deliver	
		end
		render_json_s(true) and return
	end

	def result_job
		case params[:result_type]
		when "analysis"
			# get the survey instance
			survey = Survey.find_by_id(params[:survey_id])
			render_json_e(ErrorEnum::SURVEY_NOT_EXIST) and return if survey.nil?
			# find answers set
			answers, tot_answer_number, screened_answer_number = *survey.get_answers(params[:filter_index].to_i,
																					params[:include_screened_answer].to_s == "true",
																					params[:task_id])
			# generate the result_key
			result_key = AnalysisResult.generate_result_key(answers)
			# create analysis result
			analysis_result = AnalysisResult.create(:result_key => result_key,
													:task_id => params[:task_id],
													:tot_answer_number => tot_answer_number,
													:screened_answer_number => screened_answer_number)
			survey.analysis_results << analysis_result
			# analyze and save the analysis result
			retval = analysis_result.analysis(answers, params[:task_id])
			render_json_auto(retval) and return
		when "report"
			survey = Survey.find_by_id(params[:survey_id])
			render_json_e(ErrorEnum::SURVEY_NOT_EXIST) and return if survey.nil?
			# find answers set
			answers, tot_answer_number, screened_answer_number = *survey.get_answers(params[:filter_index].to_i,
																					params[:include_screened_answer].to_s == "true",
																					params[:task_id])
			if report_mockup_id.nil?
				report_mockup = ReportMockup.default_report_mockup(survey)
			else
				report_mockup = ReportMockup.find_by_id(params[:report_mockup_id])
			end
			# generate result key
			result_key = ReportResult.generate_result_key(answers,
														report_mockup,
														params[:report_type],
														params[:report_style])
			# create new result record
			report_result = ReportResult.create(:result_key => result_key,
												:task_id => params["task_id"])
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
			retval = report_result.generate_report(report_mockup,
												params[:report_type],
												params[:report_style],
												answers_transform)
			render_json_auto(retval) and return
		when "to_spss"
			
		when "to_excel"
			
		end
	end
end
