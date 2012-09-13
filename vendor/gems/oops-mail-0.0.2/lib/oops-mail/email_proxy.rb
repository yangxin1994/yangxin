# coding: utf-8

require 'date'

module OopsMail
	module EmailProxy

		#send_message with smtp.netranking.cn
		#
		#*params*: the hash map
		#
		#* :account_name => "", account name of smtp domain.
		#* :account_secret => "", account_secret of current account_name.
		#* :mail_list => [], send_message for mail_list.each.
		#* :subject => "", mail's subject.
		#* :content => "", mail's html content.
		def send_with_netranking(args)

			account_name = args[:account_name]
			if account_name.include?('@netranking.cn') == false then
				raise ArgumentError, "Your account_name must be @netranking.cn "
			end
			account_secret = args[:account_secret]
			mail_list = args[:mail_list]
			subject = args[:subject]
			content = args[:content]

			retval_array = []
			Net::SMTP.start("smtp.netranking.cn", 25, "netranking.cn", account_name, account_secret, :login) do |smtp|
				time = DateTime.now.strftime('%a, %d %b %Y %H:%M:%S %z')
				mail_list.each do |email_addr|
					puts "send_message to #{email_addr} from #{account_name} with smtp.netranking.cn"
					
					msgstr =<<END_MESSAGE
From: <#{account_name}>
To: <#{email_addr}>
MIME-Version: 1.0
Content-type: text/html; charset=utf-8
Subject: #{subject}
Date: #{time}

#{content}
END_MESSAGE

					retval = smtp.send_message msgstr,
														account_name,
														email_addr

					retval_array << retval.success?
				end

				puts "Done!"
			end
			return true
		rescue => ex
			puts "    #{ex.class}: #{ex.message}"
			raise ex
		end

		#send_message with smtp.gmail.com
		#
		#*params*: the hash map
		#
		#* :account_name => "", account name of smtp domain.
		#* :account_secret => "", account_secret of current account_name.
		#* :mail_list => [], send_message for mail_list.each
		#* :subject => "", mail's subject
		#* :content => "", mail's html content
		def send_with_gmail(args)

			account_name = args[:account_name]
			if account_name.include?('@gmail.com') == false then
				raise ArgumentError, "Your account_name must be @gmail.com "
			end
			account_secret = args[:account_secret]
			mail_list = args[:mail_list]
			subject = args[:subject]
			content = args[:content]
		
			retval_array = []
			smtp = Net::SMTP.new 'smtp.gmail.com', 587
			smtp.enable_starttls     #587 port diff with 25
			smtp.start("gmail.com", account_name, account_secret, :plain) do |s|
				time = DateTime.now.strftime('%a, %d %b %Y %H:%M:%S %z')
				mail_list.each do |email_addr|
					puts "send_message to #{email_addr} from #{account_name} with smtp.gmail.com"

					msgstr =<<END_MESSAGE
From: <#{account_name}>
To: <#{email_addr}>
MIME-Version: 1.0
Content-type: text/html; charset=utf-8
Subject: #{subject}
Date: #{time}

#{content}
END_MESSAGE

					retval = s.send_message msgstr,
														account_name,
														email_addr

					retval_array << retval.success?
				end
				puts "Done!"
			end

			return true
		rescue => ex
			puts "    #{ex.class}: #{ex.message}"
			raise ex
		end

		#send_message with mailgun
		#
		#*params*: the hash map
		#
		#* :account_name => "", account name of smtp domain.
		#* :mail_list => [], send_message for mail_list.each
		#* :subject => "", mail's subject
		#* :content => "", mail's html content
		#* :api_domain => "", mail domain. ex: "shatler.mailgun.org"
		#* :api_key => "", mail key. ex: "key-6pbswg40chxh9fkwo7-l677mkpujbgh7"
		def send_with_mailgun(args)
			require 'rest_client'
			require 'multimap'

			api_key = "key-6pbswg40chxh9fkwo7-l677mkpujbgh7"
			api_domain = "shatler.mailgun.org"

			account_name = args[:account_name]
			mail_list = args[:mail_list]
			subject = args[:subject]
			content = args[:content]
			api_key = args[:api_key] if !args[:api_key].nil?
			api_domain = args[:api_domain] if !args[:api_domain].nil?

			##with text
			#re = RestClient.post "https://api:key-6pbswg40chxh9fkwo7-l677mkpujbgh7"\
			#"@api.mailgun.net/v2/shatler.mailgun.org/messages",
			#:from => "Excited User <postmaster@shatler.mailgun.org>",
			#:to => "#{email_addr}",
			#:subject => "Hello",
			#:text => "Testing some Mailgun awesomness! #{STIME}"
			# with html
			mail_list.each do |email_addr|
				puts "send_message to " + email_addr + " from #{account_name} with #{api_domain}"
			
				data = Multimap.new
				data[:from] = account_name
				data[:to] = email_addr
				data[:subject] = subject
				data[:html] = content
				retval = RestClient.post "https://api:#{api_key}"\
				"@api.mailgun.net/v2/#{api_domain}/messages", data

				puts "retval::#{retval}"

				# the retval should be:
				# {
				#   "message": "Queued. Thank you.",
				#   "id": "<20120809091549.2498.48248@shatler.mailgun.org>"
				# }

			end
			puts "Done!"
			return true
		rescue => ex
			puts "    #{ex.class}: #{ex.message}"
			raise ex
		end

		#
		def send_with_critsend(args)
			account_name = args[:account_name] || "market@oopsdata.com"
			account_secret = args[:account_secret] || "wZ3SWyMEDhoiq"
			mail_list = args[:mail_list]
			subject = args[:subject]
			content = args[:content]

			retval_array = []
			# format data to MaxConnect
			Net::SMTP.start("smtp.critsend.com", 25, "critsend.com", account_name, account_secret, :login) do |smtp|
				time = DateTime.now.strftime('%a, %d %b %Y %H:%M:%S %z')
				mail_list.each do |email_addr|
					puts "send_message to #{email_addr} from #{account_name} with critsend.com"
					
					msgstr =<<END_MESSAGE
From: <#{account_name}>
To: <#{email_addr}>
MIME-Version: 1.0
Content-type: text/html; charset=utf-8
Subject: #{subject}
Date: #{time}

#{content}
END_MESSAGE

					retval = smtp.send_message msgstr,
														account_name,
														email_addr

					retval_array << retval.success?
				end

				puts "Done!"
			end
			return true
		rescue => ex
			puts "    #{ex.class}: #{ex.message}"
			raise ex
		end		
	end
end
