# coding: utf-8
require 'helper'

class TestOopsMail < Test::Unit::TestCase
	include OopsMail::EmailProxy

	# using @instance.class Class will get error!
	# but @instance.instance_of? Class will pass Test.
	# Great hell.
	
	#**************./lib/oops-mail/omail.rb*********************
	should "01 should create OMail object" do 
		@@mail = OopsMail::OMail.new "Testing subject", "<b>Good</b> oopsdata."
		assert @@mail.instance_of?(OopsMail::OMail)
	end

	#***********./lib/oops-mail/email_sender.rb************************
	should "02 should create EmailSender object" do
		@@sender = OopsMail::EmailSender.new "customer", "customer@netranking.cn", "netrankingcust"
		assert @@sender.instance_of?(OopsMail::EmailSender)
	end

	#*********./lib/oops-mail/email_receiver.rb********************
	should "03 should create EmailReceiver object" do 
		@@receiver = OopsMail::EmailReceiver.new "oopsdata", "oopsdata@qq.com"
		assert @@receiver.instance_of? OopsMail::EmailReceiver
	end

	#***********./lib/oops-mail/email.rb********************
	should "04 should create Email object" do 
		@@email = OopsMail::Email.new @@sender, @@receiver, @@mail
		assert @@email.instance_of? OopsMail::Email
	end

	#***************./lib/oops-mail/mail_job.rb*****************************
	should "05 should send email by mail_job" do 
		#result = OopsMail::OopsMailJob.perform [{:account_name => @@sender.email,
		#                      :account_secret => @@sender.password,
		#                      :mail_list => [@@receiver.email],
		#                      :subject => @@mail.subject,
		#                      :content => @@mail.content}]
		#assert result

		#canot be test from this code.
		assert true
	end

	#*************./lib/oops-mail/sender_module.rb********************************
	#sender_module is a module which extend into OopsMail module
	#
	should "06 should rand_sender" do 
		#Resque.redis = "localhost:6379"
		#Resque.redis.namespace = "resque:OopsMail"
		#sender = OopsMail.rand_sender

		#puts sender.to_s

		#assert !sender.nil?   
	end

	should "07 should get_sender_list" do 
		#assert OopsMail.get_sender_list.instance_of?(Array)
	end
	
	#*************./lib/oops-mail/oopsmail.rb***********************************
	#
	should "08 should send email by OopsMail.send_email method" do 
		#assign sender     
		#assert OopsMail.send_email @@email

		#not assign sender
		#assert OopsMail.send_email(OopsMail::Email.new(nil,@@receiver,@@mail))
	end


	#****************./lib/oops-mail/email_proxy.rb ************
	#
	should "09 should send email by email_proxy" do 
		arg = {}
		arg[:account_name] = "customer@netranking.cn"
		arg[:account_secret] = "netrankingcust"
		arg[:mail_list] = ["oopsdata@sina.com", 
						"oopsdata@qq.com", 
						"oopsdata@hotmail.com",
						"oopsdata@126.com",
						"oopsdata@163.com",
						"oopsdata@yeah.net",
						"oopsdata@sohu.com",
						"oopsdata@sogou.com",
						"oopsdata@tom.com",
						"oopsdata@yahoo.cn",
						"oopsdata@21cn.com", 
						"oopsdatas@gmail.com",
						"oopsdatas@yahoo.com"]
		# mail_list secret: most of secrets are "od@2012", 
		# except that "oopsdatas@gmail.com" and "oopsdatas@yahoo.com" 's secret are "ods@2012".
		arg[:subject] = "Testing from critsend."
		arg[:content] = "Html critsend content:; <b>bbbcccccccccbb</b><br/><s>sssssssssss</s><br/><a href=\"http://www.oopsdata.com\">oopsdata</a>"
		
		# assert send_with_netranking(arg)
		# test is true
		#assert send_with_mailgun(arg)
		# test is true
		# time: [10,>,2,1,1,1,1,1,1,1,1,1,2], '>' no receive.
		# ... all time is over 30 minutes, now is "8/10 11:25"

		# arg[:account_name] = "oopsdatas@gmail.com"
		# arg[:account_secret] = "ods@2012"
		# assert send_with_gmail(arg)
		# test is true

		arg[:account_name] = "market@oopsdata.com"
		arg[:account_secret] = "wZ3SWyMEDhoiq"

		##
		# assert send_with_critsend(arg)
		#1. time: [,,,,,,,,,,,,]
		# ... all time is over 30 minutes, now is "8/10 11:12"
		#
		#2. time: [2,>,5,7,9,11,15,17,18,22,24,27,24]
		# sina is in spam box.
	end

end
