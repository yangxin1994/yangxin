# coding: utf-8
class QqUser < ThirdPartyUser

  field :nickname, :type => String
  field :gender, :type => String # male will return: "男"
  field :figureurl, :type => String

  def self.save_tp_user(response_data,current_user)
    retval = Tool.send_get_request("https://graph.qq.com/oauth2.0/me?access_token=#{response_data["access_token"]}", true)
    response_data2 = JSON.parse(retval.body.split(' ')[1])

    qq_user = QqUser.where(:website_id => response_data2["openid"]).first
    u = current_user.present? ? current_user : User.new(:status => User::REGISTERED)
    unless qq_user.present?
      
      qq_user = QqUser.create(
        :website => "qq", 
        :website_id => response_data2["openid"], 
        :user_id => u.id,
        :access_token => response_data["access_token"],
        :expires_in => response_data["expires_in"],
        :refresh_token => response_data["refresh_token"]
      )
      u.save unless current_user.present?
    else
      unless qq_user.user.present?
        qq_user.update_attributes(:user_id => u.id)  # create binding
        u.save unless current_user.present?
      else
        qq_user.update_attributes(:user_id => u.id)  if  current_user.present?
      end
    end

    qq_user.update_user_info

    return qq_user
  end


  def update_user_info
    response_data = call_method(
      http_method: 'get',
      url: 'https://graph.qq.com/user/',
      action: 'get_user_info',
      opts: {
        access_token: self.access_token,
        openid: self.website_id,
        oauth_consumer_key:  OOPSDATA[Rails.env]["qq_app_key"],
        format: 'json'
      }
    )
    attr = {}
    attr["nickname"]        = response_data["nickname"]
    attr["username"]        = response_data["nickname"]
    attr["gender"]          = response_data["gender"] == "男" ? 0 : 1
    attr.each do |k,v|
      self.user.write_sample_attribute(k,v)
    end
  end

end
