#encoding: utf-8
require 'csv'
class ImportEmail
	include Mongoid::Document

	field :email, :type => String
	field :username, :type => String

	def self.import_email(file_name)
		csv_text = File.read(file_name)
		csv = CSV.parse(csv_text, :headers => false)
		csv.each do |row|
			if row[0].to_s.include?("@")
				# if User.find_by_email(row[0]).nil? && self.find_by_email(row[0]).nil?
				ImportEmail.create(:email => row[0], :username => row[0])
				# end
			end
		end
	end

	def self.find_by_email(email)
		return self.where(:email.downcase => email.downcase).first
	end

	def self.destroy_by_email(email)
		return self.find_by_email(email).try(:destroy)
	end

	def self.random_emails(number, all_import_emails, emails_sent)
		emails = all_import_emails - emails_sent
		number = number > emails.length ? emails.length : number
		selected_email = emails.shuffle[0..number-1]
		return selected_email
	end

	def self.remove_bounce_emails
		mail_domain_ary = ["oopsdata.net",
			"oopsdata.cn",
			"one.mailgun.org",
			"two.mailgun.org",
			"three.mailgun.org",
			"four.mailgun.org",
			"five.mailgun.org",
			"six.mailgun.org",
			"seven.mailgun.org",
			"eight.mailgun.org",
			"nine.mailgun.org",
			"ten.mailgun.org",]
		mail_domain_ary.each do |domain|
			limit = 1000
			skip = 0
			all_bounced_emails = []
			loop do
				retval = Tool.send_get_request("https://api.mailgun.net/v2/#{domain}/bounces?limit=#{limit}&skip=#{skip}",
					true,
					"api",
					Rails.application.config.mailgun_api_key)
				bounced_emails = JSON.parse(retval.body)["items"]
				break if bounced_emails.blank?
				skip += limit
				all_bounced_emails += bounced_emails
			end
			# remove bounce email records
			all_bounced_emails.each do |email|
				address = email["address"]
				ImportEmail.destroy_by_email(address)
				Tool.send_delete_request("https://api.mailgun.net/v2/#{domain}/bounces/#{address}",
					{},
					true,
					"api",
					Rails.application.config.mailgun_api_key)
			end
		end
	end
end
