#encoding: utf-8
require 'csv'
class ImportEmail
	include Mongoid::Document
	field :email, :type => String
	field :username, :type => String
	field :confirm, :type => Boolean, default: false
	field :sent, :type => Boolean

	scope :confirmed, where(:confirm => true)
	scope :not_confirmed, where(:confirm.in => [false, nil])

	scope :not_sent, where(:sent => nil)

	index({ sent: 1 }, { background: true } )

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

	def self.confirm_by_email(email)
		email = self.find_by_email(email)
		return false if email.nil?
		email.confirm = true
		return email.save
	end

	def self.random_emails(number, emails_sent)
		confirmed_emails = ImportEmail.confirmed.map { |e| e.email }
		not_confirmed_emails = ImportEmail.not_confirmed.map { |e| e.email }

		confirmed_emails = confirmed_emails - emails_sent
		not_confirmed_emails = not_confirmed_emails - emails_sent

		number = number > emails.length ? emails.length : number

		not_confirmed_number = number / 20
		confirmed_number = number - not_confirmed_number

		selected_confirmed_email = confirmed_emails.shuffle[0..confirmed_number-1]
		selected_not_confirmed_email = not_confirmed_emails.shuffle[0..not_confirmed_number-1]
		return selected_confirmed_email + selected_not_confirmed_email
	end

	def self.remove_bounce_emails
		limit = 1000
		skip = 0
		all_bounced_emails = []
		loop do
			retval = Tool.send_get_request("https://api.mailgun.net/v2/oopsdata.net/bounces?limit=#{limit}&skip=#{skip}",
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
			Tool.send_delete_request("https://api.mailgun.net/v2/oopsdata.net/bounces/#{address}",
				{},
				true,
				"api",
				Rails.application.config.mailgun_api_key)
		end
	end

	def self.confirm_good_emails
		limit = 1000
		skip = 0
		loop do
			retval = Tool.send_get_request("https://api.mailgun.net/v2/oopsdata.cn/log?limit=#{limit}&skip=#{skip}",
				true,
				"api",
				Rails.application.config.mailgun_api_key)
			items = JSON.parse(retval.body)["items"]
			break if items.blank?
			items.each do |item|
				message_id = item["message_id"]
				# return if !MailgunLog.where(:message_id => message_id).first.nil?
				message_ary = item["message"].split(' ')
				MailgunLog.create(:message_id => message_id)
				ImportEmail.confirm_by_email(message_ary[3]) if message_ary[0].downcase.include?('deliver')
			end
			skip += limit
		end
	end
end
