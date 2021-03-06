class SmsWorker
  include Sidekiq::Worker
  sidekiq_options :retry => 10, :queue => "oopsdata_#{Rails.env}".to_sym

  def perform(sms_type, mobile, callback, opt={})
    case sms_type
    when 'welcome'
      retval = SmsApi.welcome_sms(sms_type, mobile, callback, opt)
    when 'activate'
      retval = SmsApi.activate_sms(sms_type, mobile, callback, opt)
    when 'rss_subscribe'
      retval = SmsApi.rss_subscribe_sms(sms_type, mobile, callback, opt)        
    when 'change_mobile'
      retval = SmsApi.activate_sms(sms_type, mobile, callback, opt)
    when 'find_password'
      retval = SmsApi.find_password_sms(sms_type, mobile, callback, opt)
    when 'charge_notification'
      retval = SmsApi.charge_confirm_sms(sms_type, mobile, callback, opt)
    when 'carnival_re_invitation'
      retval = SmsApi.carnival_re_invitation(sms_type, mobile, callback, opt)
    end
    return true
  end
end
