require 'encryption'
require 'error_enum'
require 'tool'
#Record the user from other websites
class ThirdPartyUser
  include Mongoid::Document
  # website can be "renren", "sina", "qq", "google", "qihu"
  field :website, :type => String
  field :user_id, :type => String
  field :oopsdata_user_id, :type => String
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
	  return self.where(:website => website, :user_id => user_id)[0]
	end

	#****** instance methods **********

	def is_bound(user = nil)
		return false if user.nil?
		return self.oopsdata_user_id == user._id
	end

	def bind(user)
		self.oopsdata_user_id = user._id
		return self.save
	end
	
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
