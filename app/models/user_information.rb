class UserInformation
  include Mongoid::Document
  field :email, :type => String
  field :realname, :type => String
  field :address, :type => String
  field :zipcode, :type => String
  field :telephone, :type => String
  field :gender, :type => Integer
  field :marriage, :type => Integer
  field :education, :type => Integer
  field :birthday, :type => Date
  field :location, :type => Integer
  field :family_incoming, :type => Integer
  field :personal_incoming, :type => Integer
  field :position, :type => Integer
  field :industry, :type => Integer

	key :email

	attr_accessible :email, :realname, :address, :zipcode, :telephone, :gender, :marriage, :education, :birthday, :location, :family_incoming, :personal_incoming, :position, :industry


	# check and create
	def self.check_and_create_new(user_information)
		return -1 if user_information_exist?(user_information["email"])
		user_information = UserInformation.new(user_information)
		user_information.save
	end

	# check whether user_information for one email exists
	def self.user_information_exist?(email)
		User.where(:email => email).length > 0
	end

	# update a user information
	def self.update(user_information)
		email = user_information["email"]
		if user_information_exist?(email)
			user_information = User.where(:email => email)[0]
			user_information.update_attributes(user_information)
		else
			user_information = UserInformation.new(user_information)
		end
		user_information.save
	end
end
