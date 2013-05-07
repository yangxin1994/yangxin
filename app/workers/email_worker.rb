class EmailWorker
	include Sidekiq::Worker
	sidekiq_options :retry => 10, :queue => "oopsdata_#{Rails.env}".to_sym

	def perform(email_type, email, callback, opt={})
		user = User.find_by_email(email)
		return false if user.nil?
		case email_type
		when 'welcome'
			MailgunApi.welcome_email(user, callback)
		when 'activate'
			MailgunApi.activate_email(user, callback)
		when 'password'
			MailgunApi.password_email(user, callback)
		when 'sys_password'
			MailgunApi.sys_password_email(user, callback)
		when 'lottery_code'
			MailgunApi.lottery_code_email(user, opt["survey_id"], opt["lottery_code_id"], callback)
		end
		return true
	end
end
