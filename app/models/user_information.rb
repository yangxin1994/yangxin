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



	# check whether user_information for one email exists
	def self.user_information_exist?(email)
		UserInformation.where(:email => email).length > 0
	end

	# update a user information
	def self.update(user_information)
		email = user_information["email"]
		if user_information_exist?(email)
			user_information_inst = UserInformation.where(:email => email)[0]
			puts user_information.inspect
			user_information_inst.update_attributes(user_information)
		else
			user_information_inst = UserInformation.new(user_information)
		end
		user_information_inst.save
	end
end
