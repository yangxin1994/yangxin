class SystemUser < User

	field :system_user_type, :type => Integer
	field :true_name, :type => String
	field :lock, :type => Boolean, :default => false	

	attr_accessible :email, :username, :true_name, :password, :system_user_type, :lock

	validates_presence_of :true_name, :password, :system_user_type

	MAX_TYPE = 3
	SUBCLASS = { 0 => "AnswerAuditor", 1 => "SurveyAuditor", 2=> "EntryClerk", 3=> "Interviewer" }

	#--
	# instance methods
	#++ 

	#--
	# class methods
	#++
	class << self

		#
		# verify
		#

		#*description*:
		# verify email and username when create_system_user,
		# email and username must unique, include one of them at least when create_system_user.
		#
		#*params*:
		#* new_system_user
		#
		#*retval*:
		#* ErrorEnum or true
		def verify_email_and_username(new_system_user)
			if new_system_user[:email] || new_system_user["email"] then
				new_system_user[:email] = new_system_user[:email] || new_system_user["email"]
				user = User.find_by_email(new_system_user[:email])
				return ErrorEnum::EMAIL_EXIST if user && user.is_a?(User)
			end
			if new_system_user[:username] || new_system_user["username"] then
				new_system_user[:username] = new_system_user[:username] || new_system_user["username"]
				user = User.find_by_username(new_system_user[:username])
				return ErrorEnum::USERNAME_EXIST if user && user.is_a?(User)
			end

			if (new_system_user[:username].nil? && new_system_user[:email].nil?) || 
				(new_system_user[:username] && new_system_user[:username].to_s.strip=="" &&
				new_system_user[:email] && new_system_user[:email].to_s.strip=="") then
				return ErrorEnum::SYSTEM_USER_MUST_EMAIL_OR_USERNAME
			end
			return true
		end

		#*description*: verify the system_user_type value
		#
		#*params*:
		#* type_number: the number of type: 1, 2, 4, ...
		#
		#*retval*:
		#true or ErrorEnum
		def verify_system_user_type(type_number)
		
			type_number_class = type_number.class
			temp = type_number
			type_number = type_number.to_i
			
			# if type_number is string, to_i will return 0.
			# "0" will return RangeError, "type1" will return TypeError
			return ErrorEnum::SYSTEM_USER_TYPE_ERROR if type_number_class != Fixnum && type_number == 0 && temp.to_s.strip !="0"
			
			if (type_number % 2 != 0 && type_number !=1) || 
				type_number <= 0 || type_number > 2**MAX_TYPE
				
				return ErrorEnum::SYSTEM_USER_RANGE_ERROR
			end
			return true
		end

		#
		#CRUD
		#

		#*description*:
		# different with find method, find_by_id will return ErrorEnum if not found.
		#
		#*params*:
		#* system_user_id
		#
		#*retval*:
		#* ErrorEnum or system_user instance
		def find_by_id(system_user_id)
			user = SystemUser.where(_id: system_user_id.to_s).first
			return ErrorEnum::SYSTEM_USER_NOT_EXIST if user.nil?
			return user  
		end

		#*description*:
		# create sytem_user for different type.
		#
		#*params*:
		#* new_system_user: a hash for sytem_user attributes.
		# 
		# the new_system_user has system_user_type which is integer as follows: 
		# 1 => "AnswerAuditor", 2 => "SurveyAuditor", 4=> "EntryClerk", 8=> "Interviewer"
		#
		# if new_system_user has new_system_user["type"] value,
		# the type_number value would be ignore
		#
		#*retval*:
		#* ErrorEnum or system_user instance
		def create_system_user(new_system_user)
			new_system_user[:system_user_type] = new_system_user[:system_user_type] || 1
			retval = verify_system_user_type(new_system_user[:system_user_type])
			return retval if retval != true

			#unique email and username
			retval = verify_email_and_username(new_system_user)
			return retval if retval != true

			#create
			new_system_user.select!{|k,v| %w(system_user_type email username password true_name lock).include?(k.to_s)}
			if new_system_user[:password] || new_system_user["password"] then
				new_system_user[:password] = new_system_user[:password] || new_system_user["password"]
				new_system_user[:password] = Encryption.encrypt_password(new_system_user[:password]) 
			end
			system_user = Kernel.const_get(SUBCLASS[Math.log2(new_system_user[:system_user_type].to_i).to_i]).new(new_system_user)

			# init user other attrs, disable default
			system_user.status = 2 #it is activated
			if !system_user.save then
				return ErrorEnum::SYSTEM_USER_SAVE_FAILED
			end	

			return system_user

		end

		#*description*:
		# update sytem_user 
		#
		#*params*:
		#* system_user_id
		#* attributes: update attributes
		#
		#*retval*:
		#* ErrorEnum or system_user instance
		def update_system_user(system_user_id, attributes)
			system_user = SystemUser.find_by_id(system_user_id)
			return system_user if !system_user.is_a?(SystemUser)
			attributes.select!{|k,v| %w(email password true_name lock).include?(k.to_s)}

			if attributes[:email] || attributes["email"] then
				attributes[:email] = attributes[:email] || attributes["email"]
				user = User.find_by_email(attributes[:email])
				return ErrorEnum::EMAIL_EXIST if user && user.is_a?(User) && user.id.to_s != system_user.id.to_s
			end

			if (system_user.username.nil? || system_user.username.to_s.strip=="") && attributes[:email].to_s.strip=="" then
				return ErrorEnum::SYSTEM_USER_MUST_EMAIL_OR_USERNAME 
			end

			if attributes[:password] || attributes["password"] then
				attributes[:password] = attributes[:password] || attributes["password"]
				attributes[:password] = Encryption.encrypt_password(attributes[:password]) 
			end
			if !system_user.update_attributes(attributes) then
				return ErrorEnum::SYSTEM_USER_SAVE_FAILED
			else
				return system_user
			end
		end

		#*description*:
		#
		# types		:AnswerAuditor, SurveyAuditor, EntryClerk, Interviewer.
		#
		# type number: 	 1           2               4  	        8
		#
		#*params*
		#* type_number: the search types number which is be 1, 2, 3, 7. 3=1+2; 7=1+2+4.
		#
		#*retval*:
		# a system_user array
		def list_by_type(type_number=0)

			#verify params
			return ErrorEnum::SYSTEM_USER_TYPE_ERROR if type_number && type_number.to_i ==0 && type_number.to_s.strip != "0"
			return ErrorEnum::SYSTEM_USER_RANGE_ERROR if type_number && (type_number.to_i < 0 || type_number.to_i >= 2**(MAX_TYPE+1))
			type_number = type_number.to_i
			
			return [] if !type_number.instance_of?(Fixnum) || type_number <= 0
			system_users = []
			MAX_TYPE.downto(0).each { |element| 
				system_users_tmp=[]
				if type_number / (2**element) == 1 then
					system_users_tmp = SystemUser.where(system_user_type: 2**element)
				end
				type_number = type_number % 2**element
				system_users = system_users + system_users_tmp
			}
			system_users.sort!{|v1, v2| v2.updated_at <=> v1.updated_at} if system_users.count > 1

			return system_users
		end

		#*description*:
		#
		# types		:AnswerAuditor, SurveyAuditor, EntryClerk, Interviewer.
		#
		# type number: 	 1           2               4  	        8
		#
		#*params*
		#* type_number: the search types number which is be 1, 2, 3, 7. 3=1+2; 7=1+2+4.
		#* is_lock: true or false
		#
		#*retval*:
		# a system_user array
		def list_by_type_and_lock(type_number, is_lock)

			system_users = list_by_type(type_number)

			return system_users if !system_users.instance_of?(Array)

			if system_users.count > 0 then
				system_users.select!{|o| o.lock == is_lock}
			end

			return system_users
		end

	end

end
