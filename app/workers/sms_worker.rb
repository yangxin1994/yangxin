class SmsWorker
  include Sidekiq::Worker
  sidekiq_options :retry => 10, :queue => "oopsdata_#{Rails.env}".to_sym

  def perform(sms_type, mobile, callback, opt={})
    case sms_type
    when 'welcome'
      retval = SmsApi.welcome_sms('welcome',mobile, callback, opt)
    when 'activate'
      retval = SmsApi.activate_sms('activate',mobile, callback, opt)
    when 'rss_subscribe'
      retval = SmsApi.rss_subscribe_sms('rss_subscribe',mobile, callback, opt)        
    when 'change_mobile'
      retval = SmsApi.activate_sms('change_mobile',mobile, callback, opt)
    when 'find_password'
      retval = SmsApi.find_password_sms('find_password',mobile, callback, opt)
    when 'charge_notification'
      retval = SmsApi.charge_notification('charge_notification', mobile, callback, opt)
    end
    return true
  end
end
