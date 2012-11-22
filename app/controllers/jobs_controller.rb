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
			survey = Survey.find_by_id(params[:survey_id])
			render_json_e(ErrorEnum::SURVEY_NOT_EXIST) and return if survey.nil?
			answers = survey.get_answers
			
		when "analysis"
			
		when "report"
			
		when "to_spss"
			
		when "to_excel"
			
		end
		
	end

end
