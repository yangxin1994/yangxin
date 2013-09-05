class SmsWorker
	include Sidekiq::Worker
	sidekiq_options :retry => 10, :queue => "oopsdata_#{Rails.env}".to_sym

	def perform(sms_type, mobile, callback, opt={})
		case sms_type
		when 'welcome'
			retval = SmsApi.welcome_sms(mobile, callback, opt)
		when 'activate'
			retval = SmsApi.activate_sms(mobile, callback, opt)
		when 'rss_subscribe'
			retval = SmsApi.rss_subscribe_sms(mobile, callback, opt)    	
		when 'change_mobile'
			retval = SmsApi.activate_sms(mobile, callback, opt)
		when 'find_password'
			retval = SmsApi.find_password_sms(mobile, callback, opt)
		end
		return true
	end
end
