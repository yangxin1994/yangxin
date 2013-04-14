class EmailWorker
	include Sidekiq::Worker
	sidekiq_options :retry => false, :queue => "oopsdata_#{Rails.env}".to_sym

	def perform(email_type, email, callback, opt={})
		user = User.find_by_email(email)
		return false if user.nil?
		case email_type
		when 'welcome'
			UserMailer.welcome_email(user, callback).deliver
		when 'activate'
			UserMailer.activate_email(user, callback).deliver
		when 'password'
			UserMailer.password_email(user, callback).deliver
		when 'sys_password'
			UserMailer.sys_password_email(user, callback).deliver
		when 'lottery_code'
			UserMailer.lottery_code_email(user, opt["survey_id"], opt["lottery_code_id"], callback).deliver
		end
		return true
	end
end
