# encoding: utf-8
require 'encryption'
class NewsletterMailer < ActionMailer::Base
  layout 'newsletter'

  # default to:      -> { Subscriber.all.map { |e| e.email } },
  default from:    "\"优数调研\" <postmaster@oopsdata.cn>",
          charset: "UTF-8"

  def news_email(newsletter, subscriber)

    mail(to:      subscriber.email,
         subject: newsletter.subject)
  end

end