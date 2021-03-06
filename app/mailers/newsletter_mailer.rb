# encoding: utf-8
require 'encryption'
class NewsletterMailer < ActionMailer::Base
  layout 'newsletter'

  # default to:      -> { Subscriber.all.map { |e| e.email } },
  default from:    "\"优数咨询\" <newsletter@wenjuanba.net>",
          charset: "UTF-8"

  @@test_email = "test@oopsdata.com"

  self.smtp_settings = Rails.application.config.survey_mailer_setting

  def news_email(newsletter, content_html, subscriber,  is_test = false)
    @newsletter = newsletter
    @subscriber = subscriber
    @content_html = content_html
    subject = newsletter.subject
    email = subscriber.email
    if is_test
      subject += " --- (测试)"
    else
      if Rails.env != "production"
        email = @@test_email 
        subject += " --- to #{subscriber.email}"
      end
    end
    
    mail(to:      email,
         subject: subject)
  end
end
