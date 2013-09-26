#encoding: utf-8
require 'csv'
class ImportEmail
  include Mongoid::Document
  include FindTool
  
  field :email, :type => String
  field :username, :type => String

  def self.destroy_by_email(email)
      return self.find_by_email(email.downcase).try(:destroy)
  end

  def self.remove_bounce_emails
    mail_domain_ary = ["oopsdata.net", "oopsdata.cn"]
    mail_domain_ary.each do |domain|
      limit = 1000
      skip = 0
      all_bounced_emails = []
      loop do
        retval = Tool.send_get_request(
          "https://api.mailgun.net/v2/#{domain}/bounces?limit=#{limit}&skip=#{skip}",
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
        Tool.send_delete_request(
          "https://api.mailgun.net/v2/#{domain}/bounces/#{address}",
          {},
          true,
          "api",
          Rails.application.config.mailgun_api_key)
      end
    end
  end
end
