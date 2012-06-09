require 'encryption'
require 'error_enum'
require 'tool'
#Record the user from other websites
class ThirdPartyUser
  include Mongoid::Document
  # website can be "renren", "sina", "qq", "google", "qihu"
  field :website, :type => String
  field :user_id, :type => String
  field :email, :type => String
  field :access_token, :type => String
  field :refresh_token, :type => String
  field :scope, :type => String

  #--
  # ******************* class methods ****************
  #++

	public
	
	#*description*: find a third party user from a website and an user id, 
	#
	#*params*:
	#* website
	#* user id
	#
	#*retval*:
	#* the third party user instance: when the user exists, it's only ThirdPartyUser instance.
	#* nil: when the third party user does not exist	
	def self.find_by_website_and_user_id(website, user_id)
	  website_user_class_name = website.to_s.capitalize + "User"
	  return Kernel.const_get(website_user_class_name).where(:website => website, :user_id => user_id)[0]
	end
	
	#*description*: find specifi ThirdPartyUser sub class instance
	#
	#*params*:
	#* website_user_class
	#* user id
	#
	#*retval*:
	#* the ThirdPartyUser sub class instance: like GoogleUser's instance, SinaUser's instance ...
	def self.find_by_webuserclass_and_user_id(website_user_class, user_id)
		return Kernel.const_get(website_user_class.name).where(:website => website_user_class.name.downcase.split("user")[0], :user_id => user_id)[0]
	end

  #*description*: create specifi ThirdPartyUser sub class instance, but it should not be used mostly.
	#
	#*params*:
	#* website_user_class
	#* user id
	#* access_token
	#* email=nil
	#
	#*retval*:
	#* the ThirdPartyUser sub class instance: like GoogleUser's instance, SinaUser's instance ...
	def self.create(website_user_class, user_id, access_token, email = nil)	  
		third_party_user = Kernel.const_get(website_user_class.name).new(:website => website_user_class.name.downcase.split("user")[0], :user_id => user_id, :access_token => access_token, :email => email)
		third_party_user.save
	end
	
	#*description*: update specifi ThirdPartyUser sub class instance 
	#by hash which has update attributes.
	#
	#*params*:
	#* website_user_class
	#* hash
	#
	#*retval*:
	#* the ThirdPartyUser sub class instance: like GoogleUser's instance, SinaUser's instance ...
	def self.update_by_hash(website_user_instance, hash)
	  attrs = website_user_instance.attributes
	  attrs.merge!(hash)
	  user = Kernel.const_get(website_user_instance.class.name).collection.find_and_modify(:query => {_id: website_user_instance.id}, :update => attrs, :new => true)
	  Kernel.const_get(website_user_instance.class.name).new(user)
	end
	
	#*description*: update specifi ThirdPartyUser sub class instance 
	#by hash which has update attributes.
	#
	#*params*:
	#* website_user_class
	#* email
	#
	#*retval*:
	#* the ThirdPartyUser sub class instance: like GoogleUser's instance, SinaUser's instance ...
	def self.find_by_webuserclass_and_email(website_user_class, email)
	  return Kernel.const_get(website_user_class.name).where(:website => website_user_class.name.downcase.split("user")[0], :email => email)[0]
	end
	
	
	# define token logic. 
	# it dependence on sub class methods: get_access_token, save_tp_user.
	#
	#*params*:
  #
  #*code: params of the third party return.
  #
  #*retval*:
  #
	#*[status, tp_user]:
	#status have three values(SAVE_FAILED, THIRD_PARTY_USER_NOT_BIND, EMAIL_NOT_ACTIVATED, true).
	#tp_user do not change.
  def self.token(code)
    
    #get access_token(or with user_id, expires_in and so on)
    response_data = get_access_token(code)
    
    #use access_token(or with user_id, expires_in and so on) to new or update tp_user
		tp_user = save_tp_user(response_data)		
    
    #compute status, then return status and tp_user
    compute_status(tp_user)
  rescue => e
    puts "#{e.class}: #{e.message}"
    raise e
  end
	
	#*params*: 
	#
	#*tp_user: third party user
	#
	#*retval*:
	#
	#*[status, tp_user]:
	#status have three values(SAVE_FAILED, THIRD_PARTY_USER_NOT_BIND, EMAIL_NOT_ACTIVATED, true).
	#tp_user do not change.
	def self.compute_status(tp_user)
	  Logger.new("log/development.log").info("tp_user: #{tp_user.to_s}")
    return [ErrorEnum::SAVE_FAILED, nil] if tp_user.nil?
    return [ErrorEnum::THIRD_PARTY_USER_NOT_BIND, tp_user] if tp_user.email.nil? || tp_user.email ==""
    user = User.find_by_email(tp_user.email)
    if !user.nil? then
      return [ErrorEnum::EMAIL_NOT_ACTIVATED, tp_user] if user.status == 0
    end
    return [true, tp_user]
  end
	
	#****** instance methods **********
	
	#*description*: update specifi ThirdPartyUser sub class instance 
	#by hash which has update attributes.
	#
	#*params*:
	#* hash
	#
	#*retval*:
	#* self: like GoogleUser's instance, SinaUser's instance ...
	def update_by_hash(hash)
	  attrs = self.attributes
	  attrs.merge!(hash)
	  self.class.collection.find_and_modify(:query => {_id: self.id}, :update => attrs, :new => true)
	  return self
	end
	
	#*description*: update user base info, it involves get_user_info.
	#
	#*params*: none
	#
	#*retval*:
	#* instance: a updated tp_user instance
  def update_user_info
    response_data = get_user_info
      
    #select attribute
    response_data.select!{|k,v| @select_attrs.split.include?(k.to_s) }
    
    #update
    return self.update_by_hash(response_data)
  end
	
	# it can call any methods from third_party's API. this method should be always overwrite.
	#
	#*params*:
	#
	#*opts: hash.
	def call_method(opts = {})
	  compute_params(opts)
	end
	
	# be involed from call_method method .
	#
	#*params*:
	#
	#*opts: hash.
	def compute_params(opts = {})
    @params_url = ""
    @params.merge(opts.select {|k,v| k.to_s!="method"}).each{|k, v| @params_url +="&#{k}=#{v}"}
    @params_url.sub!("&","?")
	end	
	
	#update instance's access_token and save
	def update_access_token(access_token)
		self.access_token = access_token
		return self.save
	end
	
	#update instance's refresh_token and save
	def update_refresh_token(refresh_token)
	  self.refresh_token = refresh_token
	  return self.save
	end
	
	# update instance's scope and save
	def update_scope(scope)
	  self.scope = scope
	  return self.save
	end
	
	private
	
  #*description*: judge of a text's action.
	#
	#*params*: 
	#* hash: a hash which some website response.
	#
	#*retval*:
	#* bool: true or false
  def successful?(hash)
    if hash.select{|k,v| k.to_s=~/error/}.empty? then
      return true
    else
      return false
    end   
  end
		
end
