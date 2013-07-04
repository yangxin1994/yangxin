class SurveySubscribeWorker
	include Sidekiq::Worker
	sidekiq_options :retry => 10, :queue => "oopsdata_#{Rails.env}".to_sym

	def perform(email, callback)
	  ss = SurveySubscribe.where(:subscribe_channel => email).first
	  if ss.present?
	    code = ss.active_code
	    MailgunApi.generate_active_code_email(email,code,callback)   
	  end
	      	
	  return true
	end
end
