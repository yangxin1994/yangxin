require 'quill_common'
class JobsController < ApplicationController

	def survey_deadline_job
		survey = Survey.find_by_id(params[:survey_id])
		# the publish status of the survey is set as closed
		survey.update_attributes(publish_status: QuillCommon::PublishStatusEnum::CLOSED) if survey.publish_status == QuillCommonPublishStatusEnum::PUBLISHED
		survey.refresh_quota_stats
		# delete the quota job for this survey
		TaskClient.destroy_task("quota", {survey_id: survey._id})
		# whether need to analyze results?
		render_json_s(true) and return
	end

	def email_job
		user = User.find_by_email(params[:email])
		render_json_e(ErrorEnum::USER_NOT_EXIST) and return if user.nil?
		case params[:email_type]
		when 'welcome'
			UserMailer.welcome_email(user, params[:callback]).deliver
		when 'activate'
			UserMailer.activate_email(user, params[:callback]).deliver
		when 'password'
			UserMailer.password_email(user, params[:callback]).deliver
		when 'lottery_code'
			UserMailer.lottery_code_email(user, params[:survey_id], params[:lottery_code_id], params[:callback]).deliver
		end
		render_json_s(true) and return
	end

	def quota_job
		# 1. get all samples, excluding those are in the blacklist
		user_ids = User.ids_not_in_blacklist
		# 2. get the surveys that need to send emails
		published_survey = Survey.get_published_active_surveys
		# 3. find out samples for surveys
		surveys_for_user = {}
		surveys_for_imported_email = {}
		published_survey.each do |survey|
			s_id = survey._id.to_s
			email_number = survey.promote_email_number
			user_ids_answered = survey.get_user_ids_answered
			user_ids_sent = EmailHistory.get_user_ids_sent(s_id)
			user_ids = user_ids - user_ids_answered - user_ids_sent
			samples_found = user_ids.length > email_number ? user_ids.shuffle[0..email_number-1] : user_ids
			samples_found.each do |u_id|
				surveys_for_user[u_id] ||= []
				surveys_for_user[u_id] << survey._id.to_s
			end
			if samples_found.length < email_number
				emails_sent = EmailHistory.get_emails_sent(s_id)
				ImportEmail.random_emails(email_number - samples_found.length, emails_sent).each do |email|
					surveys_for_imported_email[email] ||= []
					surveys_for_imported_email[email] << survey._id.to_s
				end
			end
		end
		# 4. send emails to the samples found
		# since this may consume long time, we do this in a separate thread
		Thread.new {
			surveys_for_user.each do |u_id, s_id_ary|
				UserMailer.survey_email(u_id, s_id_ary).deliver
			end
			surveys_for_imported_email.each do |email, s_id_ary|
				begin
					UserMailer.imported_email_survey_email(email, s_id_ary).deliver
				rescue
				end
			end
		}
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
			result_key = AnalysisResult.generate_result_key(survey.last_update_time,
				answers,
				tot_answer_number,
				screened_answer_number)
			existing_analysis_result = AnalysisResult.find_by_result_key(result_key)
			if existing_analysis_result.nil?
				# create analysis result
				analysis_result = AnalysisResult.create(:result_key => result_key,
														:task_id => params[:task_id],
														:tot_answer_number => tot_answer_number,
														:screened_answer_number => screened_answer_number)
			else
				# create analysis result
				analysis_result = AnalysisResult.create(:result_key => result_key,
														:task_id => params[:task_id],
														:tot_answer_number => tot_answer_number,
														:screened_answer_number => screened_answer_number,
														:ref_result_id => existing_analysis_result._id)
				render_json_auto(true) and return
			end
			survey.analysis_results << analysis_result
			# analyze and save the analysis result
			Thread.new {
				analysis_result.analysis(answers, params[:task_id])
			}
			render_json_auto(true) and return
		when "report"
			survey = Survey.find_by_id(params[:survey_id])
			render_json_e(ErrorEnum::SURVEY_NOT_EXIST) and return if survey.nil?
			data_list = AnalysisResult.get_data_list(params[:analysis_task_id])
			render_json_e(ErrorEnum::RESULT_NOT_EXIST) and return if data_list == ErrorEnum::RESULT_NOT_EXIST
			answer_info = data_list[:answer_info] || []
			answers = answer_info.map { |e| Answer.find_by_id e["_id"] }
			
			if params[:report_mockup_id].blank?
				report_mockup = ReportMockup.default_report_mockup(survey)
			else
				report_mockup = ReportMockup.find_by_id(params[:report_mockup_id])
			end
			# generate result key
			result_key = ReportResult.generate_result_key(survey.last_update_time,
														answers,
														report_mockup,
														params[:report_type],
														params[:report_style])

			existing_report_result = ReportResult.find_by_result_key(result_key)
			if existing_report_result.nil?
				# create new result record
				report_result = ReportResult.create(:result_key => result_key,
													:task_id => params["task_id"])
			else
				report_result = ReportResult.create(:result_key => result_key,
													:task_id => params["task_id"],
													:ref_result_id => existing_report_result._id)
				render_json_auto(true) and return
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
			Thread.new {
				report_result.generate_report(report_mockup,
												params[:report_type],
												params[:report_style],
												answers_transform)
			}
			render_json_auto(true) and return
		when "to_spss"
			survey = Survey.find_by_id(params[:survey_id])
			render_json_e(ErrorEnum::SURVEY_NOT_EXIST) and return if survey.nil?
			data_list = AnalysisResult.get_data_list(params[:analysis_task_id])
			render_json_e(ErrorEnum::RESULT_NOT_EXIST) and return if data_list == ErrorEnum::RESULT_NOT_EXIST
			answer_info = data_list[:answer_info] || []
			answers = answer_info.map { |e| Answer.find_by_id e["_id"] }
			# generate result key
			result_key = ExportResult.generate_spss_result_key(survey.last_update_time,
														answers)
			existing_export_result = ExportResult.find_by_result_key(result_key)
			if existing_export_result.nil?
				# create new result record
				export_result = ExportResult.create(:result_key => result_key,
													:task_id => params["task_id"])
			else
				export_result = ExportResult.create(:result_key => result_key,
													:task_id => params["task_id"],
													:ref_result_id => existing_export_result._id)
				render_json_auto(true) and return
			end
			survey.export_results << export_result
			Thread.new {
				retval = export_result.generate_spss(survey, answers, result_key)
			}
			render_json_auto(true) and return
		when "to_excel"
			survey = Survey.find_by_id(params[:survey_id])
			render_json_e(ErrorEnum::SURVEY_NOT_EXIST) and return if survey.nil?
			data_list = AnalysisResult.get_data_list(params[:analysis_task_id])
			render_json_e(ErrorEnum::RESULT_NOT_EXIST) and return if data_list == ErrorEnum::RESULT_NOT_EXIST
			answer_info = data_list[:answer_info] || []
			answers = answer_info.map { |e| Answer.find_by_id e["_id"] }
			# generate result key
			result_key = ExportResult.generate_excel_result_key(survey.last_update_time,
														answers)
			existing_export_result = ExportResult.find_by_result_key(result_key)
			if existing_export_result.nil?
				# create new result record
				export_result = ExportResult.create(:result_key => result_key,
													:task_id => params["task_id"])
			else
				export_result = ExportResult.create(:result_key => result_key,
													:task_id => params["task_id"],
													:ref_result_id => existing_export_result._id)
				render_json_auto(true) and return
			end
			survey.export_results << export_result
			Thread.new {
				retval = export_result.generate_excel(survey, answers, result_key)
			}
			render_json_auto(true) and return
		end
	end

	def error
		result = Result.where(:task_id => params[:task_id]).first
		render_json_auto(true) and return if result.nil?
		result.status = -1
		result.error_code = params[:error_code]
		result.error_message = params[:error_message]
		result.save
		render_json_auto(true) and return
	end
end
