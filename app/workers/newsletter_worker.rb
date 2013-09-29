# encoding: utf-8
class NewsletterWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false, :queue => "oopsdata_#{Rails.env}".to_sym

  def perform(newsletter_id, content_html)
    return unless newsletter = Newsletter.where(:_id => newsletter_id).first
    Subscriber.subscribed.each do |sub|
      return if '1' != Sidekiq.redis{|r| r.get('news_flag')}
      next if sub.newsletters.include? newsletter
      begin
        NewsletterMailer.news_email(newsletter, content_html, sub).deliver
        sub.newsletters << newsletter
        sub.save
      rescue
        p "发送出错"
      end
    end
    newsletter.status = 1 #设置发送完成标识
    newsletter.save
  end
end
