require 'encryption'
require 'error_enum'
require 'tool'
#Record the user from other websites
class ThirdPartyUser
  include Mongoid::Document
# website can be "renren", "sina", "qq", "google", "360"
  field :website, :type => String
  field :user_id, :type => String
  field :email, :type => String
  field :access_token, :type => String



	public
	#*description*: find a third party user given a website and an user id
	#
	#*params*:
	#* website
	#* user id
	#
	#*retval*:
	#* the third party user instance: when the user exists
	#* nil: when the third party user does not exist
	def self.find_by_website_and_user_id(website, user_id)
		return ThirdPartyUser.where(:website => website, :user_id => user_id)[0]
	end

	def self.create(website, user_id, access_token, email = nil)
		third_party_user = ThirdPartyUser.new(:website => website, :user_id => user_id, :access_token => access_token, :email => email)
		third_party_user.save
	end
	
	def update_access_token(access_token)
		self.access_token = access_token
		return self.save
	end
	
end
