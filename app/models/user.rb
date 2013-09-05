#is being tidied up
require 'data_type'
require 'encryption'
require 'error_enum'
require 'tool'
#Corresponding to the User collection in database. Record the user information and activities related to the usage of OopsData system.
class User
	include Mongoid::Document
	include Mongoid::Timestamps
	include Mongoid::ValidationsExt
  	EmailRexg  = '\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z'
  	MobileRexg = '^(13[0-9]|15[012356789]|18[0236789]|14[57])[0-9]{8}$' 

  	DEFAULT_IMG = '/assets/avatar/small_default.png'

	field :email, :type => String
	field :email_activation, :type => Boolean, default: false
	field :email_subscribe, :type => Boolean, default: false
	field :mobile, :type => String
	field :mobile_activation, :type => Boolean, default: false
	field :mobile_subscribe, :type => Boolean, default: false
	field :password, :type => String
	# 1 unregistered
	# 2 registered
	field :status, :type => Integer, default: 1
	field :registered_at, :type => Integer, default: 0
	# true: the user is locked and cannot login
	field :lock, :type => Boolean, default: false
	field :last_login_time, :type => Integer
	field :last_login_ip, :type => String
	field :last_login_client_type, :type => String
	field :login_count, :type => Integer, default: 0
	field :sms_verification_code, :type => String
	field :sms_verification_expiration_time, :type => Integer,default:  -> {(Time.now + 1.minutes).to_i }
  	field :rss_verification_code, :type => String
  	field :rss_verification_expiration_time, :type => Integer,default:  -> {(Time.now + 1.minutes).to_i }	
	field :email_to_be_changed, :type => String
	field :change_email_expiration_time, :type => Integer
	field :mobile_to_be_changed, :type => String
	field :change_mobile_expiration_time, :type => Integer
	field :activate_time, :type => Integer
	field :introducer_id, :type => String
	field :last_read_messeges_time, :type => Time, :default => Time.now
	# an integer in the range of [0, 63]. If converted into a binary, each digit from the most significant one indicates:
	# super admin
	# admin
	# survey auditor
	# answer auditor
	# interviewer
	# entry clerk
	field :role, :type => Integer, default: 0

	# 1 for sample, 2 for client, 4 for admin, 8 for answer auditor, 16 for interviewer
	field :user_role, :type => Integer, default: 1
	field :is_block, :type => Boolean, default: false

	# 0 normal users
	# 1 in the white list
	# 2 in the black list
	field :auth_key, :type => String
	field :auth_key_expire_time, :type => Integer
	field :level, :type => Integer, default: 0
	field :level_expire_time, :type => Integer, default: -1


	field :point, :type => Integer, :default => 0

	attr_protected :role, :level, :user_role

	has_and_belongs_to_many :messages, class_name: "Message", inverse_of: :receiver
	has_many :sended_messages, :class_name => "Message", :inverse_of => :sender
	#################################
	# QuillMe
	has_many :orders, :class_name => "Order", :inverse_of => :sample
	# QuillAdmin
	has_many :operate_orders, :class_name => "Order", :foreign_key => "operator_id"
	has_many :third_party_users
	has_many :surveys, class_name: "Survey", inverse_of: :user
	has_many :materials
	has_one  :avatar, :class_name => "Material", :inverse_of => :user
	has_many :public_notices
	has_many :question_feedbacks, class_name: "Feedback", inverse_of: :question_user
	has_many :answer_feedbacks, class_name: "Feedback", inverse_of: :answer_user
	has_many :faqs
	has_many :advertisements
	has_many :survey_invitation_histories
	has_many :answers, class_name: "Answer", inverse_of: :user
	has_many :survey_spreads
	has_and_belongs_to_many :answer_auditor_allocated_surveys, class_name: "Survey", inverse_of: :answer_auditors
	has_many :interviewer_tasks
	has_many :reviewed_answers, class_name: "Answer", inverse_of: :auditor
	has_many :logs
	has_one  :affiliated, :class_name => "Affiliated", :inverse_of => :user

	scope :sample, mod(:user_role => [2, 1])

	VISITOR = 1
	REGISTERED = 2

	SAMPLE = 1
	CLIENT = 2
	ADMIN = 4
	ANSWER_AUDITOR = 8
	INTERVIEWER = 16

	index({ email: 1 }, { background: true } )
	index({ full_name: 1 }, { background: true } )
	index({ color: 1, status: 1, role: 1 }, { background: true } )
	index({ status: 1 }, { background: true } )
	index({ introducer_id: 1, status: 1 }, { background: true } )
	index({ auth_key: 1, status: 1 }, { background: true } )
	index({ mobile: 1 }, { background: true } )
	index({ user_role: 1 }, { background: true } )
	index({ name:1},{background: true})
	index({ created_at:1},{background: true})
	index({ is_block:1},{background: true})

	validates_numericality_of :point, :greater_than_or_equal_to => 0

	public

	def self.find_by_email_mobile(email_mobile)
		return nil if email_mobile.nil?
		user = self.where(:email => email_mobile).first
		user = self.where(:mobile => email_mobile).first if user.nil?
		return user
	end

	def self.find_by_email(email)
		return nil if email.blank?
		return self.where(:email => email.try(:downcase)).first
	end

	def self.find_by_mobile(mobile)
		return nil if mobile.blank?
		return self.where(:mobile => mobile).first
	end

	def self.find_by_id(user_id)
		return self.where(:_id => user_id).first
	end

	def self.find_by_id_including_deleted(user_id)
		return self.where(:_id => user_id).first
	end

	def self.find_by_auth_key(auth_key)
		return nil if auth_key.blank?
		user = User.where(:auth_key => auth_key, :status.gt => -1)[0]
		return nil if user.nil?
		# for visitor users, auth_key_expire_time is set as -1
		if user.auth_key_expire_time > Time.now.to_i || user.auth_key_expire_time == -1
			return user
		else
			user.auth_key = nil
			user.save
			return nil
		end
	end



	def mini_avatar
		md5 = Digest::MD5.hexdigest(self.id)
		return "/uploads/avatar/mini_#{md5}.png" if File.exist?("#{Rails.root}/public/uploads/avatar/mini_#{md5}.png")
		%w( mini small thumb).each do |ver|
			return "/uploads/avatar/#{ver}_#{md5}.png" if File.exist?("#{Rails.root}/public/uploads/avatar/#{ver}_#{md5}.png")	
		end
		return "/assets/avatar/mini_default.png"	
	end


	def set_receiver_info(receiver_info)
		if self.affiliated.present?
			self.affiliated.update_attributes(:receiver_info => receiver_info)
		else
			self.create_affiliated(:receiver_info => receiver_info)
		end		
		return true
	end



	def is_activated
		return self.mobile_activation || self.email_activation
	end

	def is_admin?
		return (self.user_role.to_i & ADMIN) > 0
	end

	def is_answer_auditor?
		return (self.user_role.to_i & ANSWER_AUDITOR) > 0
	end

	def is_interviewer?
		return (self.user_role.to_i & INTERVIEWER) > 0
	end

	#生成订阅用户并发激活码或者邮件
	def self.create_rss_user(email_mobile, callback)
		user = find_by_email_mobile(email_mobile)

		account = {}
		if email_mobile.match(/#{EmailRexg}/i)
			account[:email] = email_mobile.downcase	    
		elsif email_mobile.match(/#{MobileRexg}/i)
			active_code = Tool.generate_active_mobile_code
			account[:mobile] = email_mobile
			account[:rss_verification_code] = active_code
			account[:rss_verification_expiration_time] = (Time.now + 2.hours).to_i
		end

		new_user = true  # default imagagine the user is a new user
		if user.present? && user.status == REGISTERED
			if email_mobile.match(/#{EmailRexg}/i)
				account[:email_subscribe] = true
			else
				account[:mobile_subscribe] = true
			end
			user.update_attributes(account)
			new_user = false		
		else
			if user.present? && email_mobile.match(/#{MobileRexg}/i)
				user.update_attributes(account)
			elsif !user.present?
				account[:registered_at] = Time.now.to_i
				account[:status] = VISITOR
				user = User.create(account)				 
			end				

			if active_code.present?
				SmsWorker.perform_async("rss_subscribe", user.mobile, "", :code => active_code)
			else
				if account[:email]					
					EmailWorker.perform_async("rss_subscribe",
						user.email,
						callback[:protocol_hostname],
						callback[:path])
				end
			end			
		end		
		return {:success => true, :new_user => new_user}
	end

	#订阅邮件激活
	def self.activate_rss_subscribe(active_info)
		email = active_info['email']
		time  = active_info['time']   
		user  = User.where(:email => email).first
		return ErrorEnum::USER_NOT_EXIST if !user.present?
		return ErrorEnum::ACTIVATE_EXPIRED if Time.now.to_i - time.to_i > OOPSDATA[RailsEnv.get_rails_env]["activate_expiration_time"].to_i        
		user.update_attributes(:email_subscribe => true )
		return true
	end

	def make_mobile_rss_activate(code)
		return ErrorEnum::ACTIVATE_EXPIRED if Time.now.to_i  > self.rss_verification_expiration_time
		return ErrorEnum::ACTIVATE_CODE_ERROR if self.rss_verification_code != code
		return self.update_attributes(:mobile_subscribe => true)
	end

	def self.cancel_subscribe(active_info)
		email_mobile  = active_info['email_mobile']
		mobile = active_info['mobile']
		user = User.find_by_email_mobile(email_mobile)
		return ErrorEnum::USER_NOT_EXIST unless user.present?
		user.update_attributes(:email_subscribe => false) if email_mobile.match(/#{EmailRexg}/i)
		user.update_attributes(:mobile_subscribe => false) if email_mobile.match(/#{MobileRexg}/i)
		return {:success => true}
	end

	def self.send_forget_pass_code(email_mobile, callback)
		sample = self.find_by_email_mobile(email_mobile) 
		if sample.present?
			if(email_mobile.match(/#{MobileRexg}/i))
				active_code = Tool.generate_active_mobile_code	
				sample.update_attributes(:sms_verification_code => active_code, :sms_verification_expiration_time => (Time.now + 2.hours).to_i)
				return SmsWorker.perform_async("find_password", email_mobile, "", :code => active_code)
			else
				return EmailWorker.perform_async("find_password",
					email_mobile,
					callback[:protocol_hostname],
					callback[:path])
			end
		else
			return ErrorEnum::USER_NOT_EXIST
		end
	end


	def self.forget_pass_mobile_activate(mobile,code)
		sample = self.find_by_mobile(mobile)
		if sample.present?
			return ErrorEnum::ACTIVATE_EXPIRED if Time.now.to_i  > sample.sms_verification_expiration_time
			return ErrorEnum::ACTIVATE_CODE_ERROR if sample.sms_verification_code != code
			return true
		else
			return ErrorEnum::USER_NOT_EXIST
		end
	end

	def self.generate_new_password(email_mobile,password)
		sample = self.find_by_email_mobile(email_mobile)		
		if sample.present?
			password = Encryption.encrypt_password(password)
			return sample.update_attributes(:password => password)
		else
			return ErrorEnum::USER_NOT_EXIST
		end
	end

	#*description*: create a new user
	#
	#*params*:
	#* a user hash
	#
	#*retval*:
	#* the new user instance: when successfully created
	def self.create_new_user(email_mobile, password, current_user, third_party_user_id, callback)
		account = {}
		if email_mobile.match(/#{EmailRexg}/i)  ## match email
			account[:email] = email_mobile.downcase
		elsif email_mobile.match(/#{MobileRexg}/i)  ## match mobile
			active_code = Tool.generate_active_mobile_code
			account[:mobile] = email_mobile
		end
		return ErrorEnum::ILLEGAL_EMAIL_OR_MOBILE if account.blank?
		existing_user = account[:email] ? self.find_by_email(account[:email]) : self.find_by_mobile(account[:mobile])
		#return ErrorEnum::USER_REGISTERED if existing_user && existing_user.status == REGISTERED
		return ErrorEnum::USER_REGISTERED if existing_user && existing_user.is_activated
		password = Encryption.encrypt_password(password) if account[:email]
		account[:status] =  REGISTERED
		account[:sms_verification_code] = active_code if account[:mobile]
		account[:sms_verification_expiration_time]  = (Time.now + 2.hours).to_i
		updated_attr = account.merge(
			password: password,
			registered_at: Time.now.to_i)

		#existing_user = User.create if check_exist.nil?
		existing_user = User.create if existing_user.nil?
		existing_user.update_attributes(updated_attr)
		if active_code.present?
			SmsWorker.perform_async("welcome", existing_user.mobile, "", :active_code => active_code)
		else
			if account[:email]
				EmailWorker.perform_async("welcome",
					existing_user.email,
					callback[:protocol_hostname],
					callback[:path])
			end
		end

		# send welcome email
		## TODO  send_mobile_message() if account[:mobile]
		if !third_party_user_id.nil?
			# bind the third party user if the id is provided
			third_party_user = ThirdPartyUser.find_by_id(third_party_user_id)
			third_party_user.bind(existing_user) if !third_party_user.nil?
		end
		return true
	end


	def completed_info
		affiliated = self.affiliated
		if affiliated
			complete = 0
			affiliated.attributes.each_key do |attr_name|
				if SampleAttribute::BASIC_ATTR.include?(attr_name)
					complete += 1
				end	
			end
			basic_attr = SampleAttribute::BASIC_ATTR.length
			return complete * 100 / basic_attr
		else
			return 0 
		end
	end


	#*description*: activate a user
	#
	#*params*:
	#* an activate info hash, which has the following keys
	#  - email: the email address of the user
	#  - time: the time the activat email is sent
	#
	#*retval*:
	#* true: when successfully activated or already activated
	def self.activate(activate_type, activate_info, client_ip, client_type, password = nil)
		user = User.find_by_email(activate_info["email"]) if activate_type == "email"
		user = User.find_by_mobile(activate_info["mobile"]) if activate_type == "mobile"
		return ErrorEnum::USER_NOT_EXIST if user.nil?     # email account does not exist
		if activate_type == "email"
			# email activate
			return ErrorEnum::USER_NOT_REGISTERED if user.status == VISITOR
			return ErrorEnum::ACTIVATE_EXPIRED if Time.now.to_i - activate_info["time"].to_i > OOPSDATA[RailsEnv.get_rails_env]["activate_expiration_time"].to_i    # expired
			user.email_activation = true
			user.activate_time = Time.now.to_i
			user.email_subscribe = true
		else
			# mobile activate
			#return ErrorEnum::USER_NOT_REGISTERED if user.status == VISITOR
			return ErrorEnum::ILLEGAL_ACTIVATE_KEY if user.sms_verification_code != activate_info["verification_code"]
			return ErrorEnum::ACTIVATE_EXPIRED if Time.now.to_i  > user.sms_verification_expiration_time
			user.password = Encryption.encrypt_password(activate_info["password"])
			user.mobile_activation = true
			user.activate_time = Time.now.to_i
			user.mobile_subscribe = true
		end
		user.save
		RegistLog.create_regist_log(user.id)
		return user.login(client_ip, client_type, false)
	end

	def change_email(client_ip)
		return ErrorEnum::ACTIVATE_EXPIRED if Time.now.to_i > change_email_expiration_time
		self.email = self.email_to_be_changed
		return self.login(client_ip, nil, false)
	end

	#*description*: user login
	#
	#*params*:
	#* email address of the user
	#* password of the user
	#* ip address of the user
	#
	#*retval*:
	#* true: when successfully login
	#* EMAIL_NOT_EXIST
	#* EMAIL_NOT_ACTIVATED
	#* WRONG_PASSWORD
	def self.login_with_email_mobile(email_mobile, password, client_ip, client_type, keep_signed_in, third_party_user_id)
		user = nil
		if email_mobile.match(/#{EmailRexg}/i)  ## match email
			user = User.find_by_email(email_mobile.downcase)
		elsif email_mobile.match(/#{MobileRexg}/i)  ## match mobile
			user = User.find_by_mobile(email_mobile)
		end
		return ErrorEnum::USER_NOT_EXIST if user.nil?
		return ErrorEnum::USER_NOT_REGISTERED if user.status == 1
		return ErrorEnum::USER_NOT_ACTIVATED if !user.is_activated
		return ErrorEnum::WRONG_PASSWORD if user.password != Encryption.encrypt_password(password)
		if !third_party_user_id.nil?
			# bind the third party user if the id is provided
			third_party_user = ThirdPartyUser.find_by_id(third_party_user_id)
			third_party_user.bind(user) if !third_party_user.nil?
		end
		return user.login(client_ip, client_type, keep_signed_in)
	end


	def login(client_ip, client_type, keep_signed_in=false)
		self.last_login_ip = client_ip
		self.last_login_client_type = client_type
		self.login_count = 0 if self.last_login_time.blank? || Time.at(self.last_login_time).day != Time.now.day
		return ErrorEnum::LOGIN_TOO_FREQUENT if self.login_count > OOPSDATA[RailsEnv.get_rails_env]["login_count_threshold"]
		return ErrorEnum::USER_LOCKED if self.lock
		self.login_count = self.login_count + 1
		self.last_login_time = Time.now.to_i
		self.auth_key = Encryption.encrypt_auth_key("#{self._id}&#{Time.now.to_i.to_s}")
		self.auth_key_expire_time =  keep_signed_in ? -1 : Time.now.to_i + OOPSDATA["login_keep_time"].to_i
		return false if !self.save
		return {"auth_key" => self.auth_key}
	end


	#*description*: reset password for an user, used when the user resets its password
	#
	#*params*:
	#* old password of the user
	#* new password of the user
	#
	#*retval*:
	#* true: when successfully login
	#* WRONG_PASSWORD
	def reset_password(old_password, new_password)
		return ErrorEnum::WRONG_PASSWORD if self.password != Encryption.encrypt_password(old_password)  # wrong password
		self.password = Encryption.encrypt_password(new_password)
		return self.save
	end


	############### operations about message#################
	#++
	#ctreate
	def create_message(title, content, receiver = [])
		m = sended_messages.create(:title => title, :content => content, :type => 0) if receiver.size == 0
		m = sended_messages.create(:title => title, :content => content, :type => 1) if receiver.size >= 1
		return m unless m.is_a? Message
		receiver.each do |r|
			u = User.find_by_email(r.to_s) || User.find_by_id(r)
			next unless u
			u.messages << m# => unless m.created_at.nil?
			u.save
		end
		m
	end

	def update_message(message_id, update_attrs)
		m = Message.where(_id: message_id)[0]
		return ErrorEnum::MESSAGE_NOT_FOUND unless m
		m.update_attributes(update_attrs)
		m.save
	end


	def unread_messages_count
		Message.unread(last_read_messeges_time).select{ |m| (message_ids.include? m.id) or (m.type == 0)}.count
	end

	#--
	############### operations about point #################
	#++
	# admin inc
	def operate_point(amount, remark)
		self.point += amount.to_i
		PointLog.create_admin_operate_point_log(amount, remark, self._id) if self.save
	end
	#--

	#--
	# **************************************************
	# Quill AdminController
	#++

	public

	COLOR_NORMAL = 0

	scope :normal_list, where(:color => COLOR_NORMAL, :status.gt => -1)



	def set_sample_role(role)
		self.user_role = role.sum
		return self.save
	end



	def remove_user
		self.status = -1
		self.save
	end

	def recover
		self.status = 4
		self.save
	end

	# def add_point(point_int)
	# 	self.point += point_int
	# 	self.save
	# end

	def change_to_system_password
		# generate rand number
		sys_pwd = 1
		while sys_pwd < 16**7 do
			sys_pwd = rand(16**8-1)
		end
		sys_pwd = sys_pwd.to_s(16)
		self.password = Encryption.encrypt_password(sys_pwd)
		if !self.save then
			return ErrorEnum::USER_SAVE_FAILED
		end
		self[:new_password] = sys_pwd
		return self
	end

	def self.list_system_user(role, lock)
		role = role.to_i & 15
		selected_users = []
		users = User.where(:role.gt => 0)
		users.each do |u|
			next if u.role & role == 0
			if !lock.nil?
				next if u.lock != lock
			end
			selected_users << u
		end
		return selected_users
	end

	def spread_count
		Answer.where(:introducer_id => self.id).finished.count	
	end

	def get_introduced_users
		introduced_users = User.where(:introducer_id => self._id.to_s, :status.gt => 1).desc(:created_at)
		summary_info = introduced_users.map { |u| { _id: u._id.to_s, email: u.email, registered_at: u.registered_at } }
		return summary_info
	end

	def get_survey_ids_answered
		survey_ids = self.answers.map { |e| e.survey_id.to_s }
		return survey_ids.uniq
	end

	def self.search_sample(email, mobile, is_block)
		samples = User
		# samples = User.sample
		samples = samples.where(:is_block => false) if !is_block
		samples = samples.where(:email => /#{email.to_s}/) if !email.blank?
		samples = samples.where(:mobile => /#{mobile.to_s}/) if !mobile.blank?
		return samples
	end

	def self.count_sample(period, time_length)
		normal_sample_number = User.sample.where(:is_block => false).length
		block_sample_number = User.sample.where(:is_block => true).length
		seconds_per_period_ary = {"year" => 1.years.to_i,
			"month" => 1.months.to_i,
			"week" => 1.weeks.to_i,
			"day" => 1.days.to_i}
		seconds_per_period = seconds_per_period_ary.has_key?(period) ? seconds_per_period_ary[period] : 1.months.to_i
		time_duration = time_length * seconds_per_period
		start_time = Time.at(Time.now.to_i - time_duration)
		new_samples = User.sample.where(:created_at.gt => start_time)
		time_point_ary = (0..time_length-1).to_a
		time_point_ary.map! { |e| e * seconds_per_period + start_time.to_i}
		new_sample_number = []
		time_point_ary.each do |time_point|
			new_sample_number << User.sample.and(:created_at.gte => Time.at(time_point), :created_at.lt => Time.at(time_point + seconds_per_period)).length
		end
		return {"normal_sample_number" => normal_sample_number,
			"block_sample_number" => block_sample_number,
			"new_sample_number" => new_sample_number}
	end

	def self.count_active_sample(period, time_length)
		seconds_per_period_ary = {"year" => 1.years.to_i,
			"month" => 1.months.to_i,
			"week" => 1.weeks.to_i,
			"day" => 1.days.to_i}
		seconds_per_period = seconds_per_period_ary.has_key?(period) ? seconds_per_period_ary[period] : 1.months.to_i
		time_duration = time_length * seconds_per_period
		start_time = Time.at(Time.now.to_i - time_duration)
		time_point_ary = (0..time_length-1).to_a
		time_point_ary.map! { |e| e * seconds_per_period + start_time.to_i}
		active_sample_number = []
		time_point_ary.each do |time_point|
			logs = Log.where(:created_at.gte => Time.at(time_point), :created_at.lt => Time.at(time_point + seconds_per_period))
			active_sample_number << logs.map {|e| e.user_id}.uniq.length
		end
		return active_sample_number
	end

	def self.make_sample_attribute_statistics(sample_attribute)
		name = sample_attribute.name.to_sym
		analyze_requirement = sample_attribute.analyze_requirement
		completion = 100 - User.where(name => nil).length * 100 / User.all.length
		analyze_result = {}
		attributes = User.only(name).where(name.ne => nil)
		case sample_attribute.type
		when DataType::ENUM
			distribution = Array.new(sample_attribute.enum_array.length) { 0 }
			attributes.each do |e|
				attribute = e.name
				distribution[attribute] = distribution[attribute] + 1
			end
			analyze_result["distribution"] = distribution
		when DataType::ARRAY
			distribution = Array.new(sample_attribute.enum_array.length) { 0 }
			attribute.each do |e|
				attribute = e.name
				attribute.each do |a|
				distribution[a] = distribution[a] + 1
				end
			end
			analyze_result["distribution"] = distribution
		when DataType::ADDRESS
			distribution = QuillCommon::AddressUtility.province_hash
			attribute.each do |e|
				address = e.name
				distribution.each do |k, v|
					if QuillCommon::AddressUtility.satisfy_region_code?(e.name, k)
						v["count"] += 1
						break
					end
				end
			end
			analyze_result["distribution"] = distribution
		when DataType::NUMBER
			segmentation = analyze_requirement["segmentation"] || []
			attribute_value = attribute.map { |e| e.name }
			analyze_result["distribution"] = Tool.calculate_segmentation_distribution(segmentation, attribute_value)
		when DataType::NUMBER_RANGE
			segmentation = analyze_requirement["segmentation"] || []
			attribute_value = attribute.map { |e| e.name.mean }
			analyze_result["distribution"] = Tool.calculate_segmentation_distribution(segmentation, attribute_value)
		when DataType::DATE
			segmentation = analyze_requirement["segmentation"] || []
			attribute_value = attribute.map { |e| e.name }
			analyze_result["distribution"] = Tool.calculate_segmentation_distribution(segmentation, attribute_value)
		when DataType::DATE_RANGE
			segmentation = analyze_requirement["segmentation"] || []
			attribute_value = attribute.map { |e| e.name.mean }
			analyze_result["distribution"] = Tool.calculate_segmentation_distribution(segmentation, attribute_value)
		end
		return [completion, analyze_result]
	end

	def spread_logs
		answers = Answer.where(:introducer_id => self._id.to_s)
		ret_logs = answers.map do |e|
			{
				"_id" => e._id.to_s,
				"title" => e.survey.title,
				"created_at" => e.created_at,
				"finished_at" => Time.at(e.finished_at),
				"email" => e.user.try(:email),
				"mobile" => e.user.try(:mobile),
				"status" => e.status,
				"reject_type" => e.reject_type
			}
		end
		return ret_logs
	end

	def block(block)
		self.is_block = block.to_s == "true"
		return self.save
	end

	def basic_info
		attributes = {}
		SampleAttribute.normal.each do |e|
			name = e.name
			case e.type
			when DataType::STRING
				attributes[name] = self.read_attribute(e.name)
			when DataType::ENUM
				gender = self.read_attribute(e.name)
				attributes[name] = gender.nil? ? nil : e.enum_array[gender]
			when DataType::ARRAY
				attributes[name] = []
				(self.read_attribute(e.name) || []).each { |m| attributes[name] << e.enum_array[m] }
			when DataType::NUMBER
				attributes[name] = self.read_attribute(e.name)
			when DataType::DATE
				attributes[name] = {
					"date_type" => e.date_type,
					"value" => self.read_attribute(e.name)
					}
			when DataType::NUMBER_RANGE
				attributes[name] = self.read_attribute(e.name)
			when DataType::DATE_RANGE
				attributes[name] = {
					"date_type" => e.date_type,
					"value" => self.read_attribute(e.name)
					}
			end
		end
		return {:email => self.email,
			:mobile => self.mobile,
			:point => self.point,
			:attributes => attributes,
			:is_block => self.is_block}
	end

	def serialize_for(arr_fields)
		user_obj = {"id" => self.id.to_s}
		arr_fields.each do |field|
			if [:created_at, :updated_at].include?(field)
				user_obj[field] = self.send(field).to_i
			else
				user_obj[field] = self.send(field)
			end
		end
		return user_obj
	end

	def sample_attributes
		sample = {
			"email" => self.email,
			"mobile" => self.mobile
		}
		SampleAttribute.normal.each do |s|
			sample[s.name] = self.read_sample_attribute(s.name)
		end
		return sample
	end

	def need_update_attribute(attr_name, updated_value)
		sa = SampleAttribute.find_by_name(attr_name)
		return false if sa.nil?
		return true if ![DataType::NUMBER_RANGE, DataType::DATE_RANGE].include?(sa.type)
		sa_value = self.read_sample_attribute(attr_name)
		return true if sa_value.nil?
		return false if Tool.range_compare(sa_value, updated_value) == -1
		return true
	end

	def read_sample_attribute(name)
		sa = SampleAttribute.find_by_name(name)
		return nil if sa.nil?
		return nil if self.affiliated.nil?
		return self.affiliated.read_attribute(sa.name.to_sym)
	end

	def read_sample_attribute_by_id(sa_id)
		sa = SampleAttribute.find_by_id(sa_id)
		return nil if sa.nil?
		return nil if self.affiliated.nil?
		return self.affiliated.read_attribute(sa.name.to_sym)
	end

	def write_sample_attribute(name, value)
		sa = SampleAttribute.find_by_name(name)
		return false if sa.nil?
		self.create_affiliated if self.affiliated.nil?
		self.affiliated.write_attribute(sa.name.to_sym, value)
		return self.affiliated.save
	end

	def write_sample_attribute_by_id(sa_id, value)
		sa = SampleAttribute.find_by_id(sa_id)
		return false if sa.nli?
		self.create_affiliated if self.affiliated.nil?
		self.affiliated.write_attribute(sa.name.to_sym, value)
		return self.affiliated.save
	end

	def get_basic_attributes
		basic_attributes = {}
		SampleAttribute::BASIC_ATTR.each do |attr_name|
			basic_attributes[attr_name] = self.read_sample_attribute(attr_name)
		end
		return basic_attributes
	end

	def set_basic_attributes(basic_attributes)
		basic_attributes.each do |attr_name, attr_value|
			next if !SampleAttribute::BASIC_ATTR.include?(attr_name)
			if self.need_update_attribute(attr_name, attr_value)
				self.write_sample_attribute(attr_name, attr_value)
			end
		end
		return true
	end

	def nickname
		nickname = self.read_sample_attribute("nickname")
		if nickname.nil?
			nickname = self.email.split('@')[0] if !self.email.blank?
			nickname ||= self.mobile
		end
		return nickname
	end

end
