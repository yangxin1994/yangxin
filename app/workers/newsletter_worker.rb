# encoding: utf-8
class NewsletterWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false, :queue => "oopsdata_#{Rails.env}".to_sym

  def perform(newsletter_id, content_html, protocol_hostname, callback)
    return unless newsletter = Newsletter.where(:_id => newsletter_id).first
    begin
      MailgunApi.newsletter(newsletter, content_html, protocol_hostname, callback)
    rescue
        p "发送出错"
    else
      newsletter.status = 1 #设置发送完成标识
      newsletter.save
    end
  end
end
