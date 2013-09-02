class EmailWorker
	include Sidekiq::Worker
	sidekiq_options :retry => 10, :queue => "oopsdata_#{Rails.env}".to_sym

	def perform(email_type, email, protocol_hostname, callback, opt={})
		if email_type != "change_email"
			user = User.find_by_email(email)
		else
			user = User.find_by_id(opt["user_id"])
		end
		return false if user.nil?
		case email_type
		when 'welcome'
			MailgunApi.welcome_email(user, protocol_hostname, callback)
		when 'rss_subscribe'
			MailgunApi.rss_subscribe_email(user, protocol_hostname, callback)    	
		when 'change_email'
			MailgunApi.change_email(user, protocol_hostname, callback)
		when 'find_password'
			MailgunApi.find_password_email(user, protocol_hostname, callback)
		end
		return true
	end
end
