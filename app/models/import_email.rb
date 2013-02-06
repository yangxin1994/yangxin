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
				if User.find_by_email(row[0]).nil? && self.find_by_email(row[0]).nil?
					ImportEmail.create(:email => row[0], :username => row[0])
				end
			end
		end
	end

	def self.find_by_email(email)
		return self.where(:email => email).first
	end

	def self.destroy_by_email(email)
		return self.find_by_email(email).try(:destroy)
	end

	def self.random_emails(number, emails_sent)
		emails = ImportEmail.all.map { |e| e.email }
		emails = emails - emails_sent
		number = number > emails.length ? emails.length : number
		selected_email = emails.shuffle[0..number-1]
		return selected_email
	end
end
