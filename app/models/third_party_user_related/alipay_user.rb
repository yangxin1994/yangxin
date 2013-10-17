# coding: utf-8
require "base64"
require 'uri'
require 'tool'
class AlipayUser < ThirdPartyUser

  def self.save_tp_user(response_data,current_user)

    alipay_user = AlipayUser.where(:website_id => response_data[:param_obj]["user_id"]).first
    alipay_user = AlipayUser.where(:user_id => current_user.id).first if current_user.present?
    u = current_user.present? ? current_user : User.new(:status => User::REGISTERED)

    unless alipay_user.present?  # create binding
      alipay_user = AlipayUser.create(
        :website => "alipay", 
        :website_id => response_data[:param_obj]["user_id"], 
        :user_id => u.id,
        :access_token => response_data[:param_obj]["token"],
      )
      u.save unless current_user.present?
    end    

    alipay_user.update_user_info(response_data)

    return alipay_user
  end


  def self.generate_para
    access_token_param ={
      "service" => "alipay.auth.authorize",
      "partner" => OOPSDATA[Rails.env]["alipay_app_key"],
      "_input_charset" => "utf-8",
      "return_url" => OOPSDATA[Rails.env]["alipay_redirect_uri"],
      "target_service" => "user.auth.quick.login"
    }
    str = ''
    access_token_param.sort.map{|k,v| str += "&#{k}=#{v}"}
    str = str.sub!('&','')
    str += OOPSDATA[Rails.env]["alipay_app_secret"]
    access_token_param["sign"] = Digest::MD5.hexdigest(str)
    access_token_param["sign_type"] = "MD5"
    tmp = ''
    access_token_param.sort.map{|k,v| tmp += "&#{k}=#{v}"}
    return tmp
  end


  def update_user_info(response_data)
    attr = {}
    attr["nickname"]        = response_data[:param_obj]["real_name"] unless self.user.read_sample_attribute('nickname').present?
    attr["username"]        = response_data[:param_obj]["real_name"] unless self.user.read_sample_attribute('username').present?
    attr.each do |k,v|
      self.user.write_sample_attribute(k,v)
    end
    self.update_attributes(
                            :nick => response_data[:param_obj]["real_name"],
                            :share => true,
                            :website_id => response_data[:param_obj]["user_id"],
                            :access_token => response_data[:param_obj]["token"]
                          )

  end

end
