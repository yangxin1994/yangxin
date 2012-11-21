class JobsController < ApplicationController

	def email_job
		user = User.find_by_email(params[:email])
		case params[:email_type]
		when 'welcome'
			UserMailer.welcome_email(user).deliver
		when 'activate'
			UserMailer.activate_email(user).deliver
		when 'password'
			UserMailer.password_email(user).deliver
		end
		render_json_s(true)
	end

end
