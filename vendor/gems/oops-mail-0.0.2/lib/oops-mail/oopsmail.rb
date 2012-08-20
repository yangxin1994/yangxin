# coding: utf-8

require 'net/smtp'
require 'email'
require 'date'
require 'mail_job'
require 'sender_module'
require 'resque_scheduler'

module OopsMail
  extend SenderModule

  #*params*
  #
  #* emails: OopsMail::Email Array.
  #* send_at: Time object or timestamps.
  #* priority: queues priority. Diff worker will get it .Include: ["low","middle","high", "supper"], default is low.
  #* mailler: ["netranking", "gmail", "mailgun"], default is netranking.
  def self.send_email(emails, send_at=nil, priority=1, mailler ="netranking")
    if !(emails.instance_of? Array) && !(emails.instance_of? OopsMail::Email)then
      raise ArgumentError, "The params emails is illegal."
    end

    _emails = []
    if emails.instance_of? OopsMail::Email then
      _emails.push(emails)
    end

    if emails.instance_of? Array then
      boo = true
      emails.each do |email|
        if !(email.instance_of? OopsMail::Email) then
          boo= false
          break
        end
      end
      raise ArgumentError, "The emails is illegal." if !boo
      _emails = emails if boo
    end
    
		puts "send_mail...."

    # OopsEmail defines in the ./oops-mail/email_job.rb
		send_at = Time.now if send_at.nil?
		if send_at.instance_of? Time then
		  send_at = send_at.to_i
		elsif send_at.instance_of? DateTime then
			send_at = send_at.to_time.to_i
		end

    _emails.each do |email|

      mail_list =[]
		  email.receiver.each do |recer|
		    mail_list.push recer.email
		  end
		
      if email.sender.nil? then
        sender = rand_sender
      else
        sender = email.sender
      end
      puts "sender_email: " + sender.email.to_s
      
      if sender.api_key.nil? then
        Resque.enqueue_at_with_queue(priority.to_s, send_at, OopsMailJob,{
          :mailler => mailler,
          :account_name => sender.email,
          :account_secret => sender.password,
          :mail_list => mail_list,
          :subject => email.mail.subject,
          :content => email.mail.content
        })
      else
        Resque.enqueue_at_with_queue(priority.to_s, send_at, OopsMailJob,{
          :mailler => mailler,
          :account_name => sender.email,
          :account_secret => sender.password,
          :api_key => sender.api_key,
          :api_domain => sender.api_domain,
          :mail_list => mail_list,
          :subject => email.mail.subject,
          :content => email.mail.content
        })
      end
    end

  rescue => ex
    puts "    #{ex.class}: #{ex.message}"
    return false
  end
  
end
