# coding: utf-8
class QqUser < ThirdPartyUser

  field :nickname, :type => String
  field :gender, :type => String # male will return: "男"
  field :figureurl, :type => String

  def self.save_tp_user(response_data,current_user)
    retval = Tool.send_get_request("https://graph.qq.com/oauth2.0/me?access_token=#{response_data['access_token']}", true)
    response_data2 = JSON.parse(retval.body.split(' ')[1])

    qq_user = QqUser.where(:website_id => response_data2["openid"]).first
    qq_user = QqUser.where(:user_id => current_user.id).first if current_user.present?
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
    end

    qq_user.update_user_info(response_data,response_data2)

    return qq_user
  end


  def update_user_info(data,response_data2)
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
    attr["nickname"]        = response_data["nickname"] unless self.user.read_sample_attribute('nickname').present? 
    attr["username"]        = response_data["nickname"] unless self.user.read_sample_attribute('username').present?
    attr["gender"]          = response_data["gender"] == "男" ? 0 : 1  unless self.user.read_sample_attribute('gender').present?
    attr.each do |k,v|
      self.user.write_sample_attribute(k,v)
    end
    self.update_attributes(
      :nick => response_data["nickname"],
      :share => true,
      :website_id => response_data2["openid"],
      :access_token => data["access_token"],
      :expires_in => data["expires_in"],
      :refresh_token => data["refresh_token"]
    )

  end

end
