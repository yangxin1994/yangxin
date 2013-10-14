# coding: utf-8
class TecentUser < ThirdPartyUser

  def self.save_tp_user(response_data,current_user)
    tecent_user = TecentUser.where(:website_id => response_data["openid"]).first
    u = current_user.present? ? current_user : User.new(:status => User::REGISTERED)
    unless tecent_user.present?  # create binding
      tecent_user = TecentUser.create(:website => "tecent", :website_id => response_data["openid"], :user_id => u.id,:access_token => response_data["access_token"])
      u.save unless current_user.present?
    else
      unless tecent_user.user.present?
        tecent_user.update_attributes(:user_id => u.id)  # create binding
        u.save unless current_user.present?
      else
        tecent_user.update_attributes(:user_id => u.id)  if  current_user.present?  #update binding
      end
    end    

    tecent_user.update_user_info

    return tecent_user
  end

  def update_user_info
    response_data = call_method(
      http_method: 'get',
      url: 'https://open.t.qq.com/api/',
      action: 'user/info',
      opts: {
        clientip: '127.0.0.1',
        oauth_version: '2.a',
        access_token: self.access_token,
        openid: self.website_id,
        oauth_consumer_key: OOPSDATA[Rails.env]["tecent_app_key"],
        format: 'json'
      }
    )
    response_data = response_data["data"]
    birthday = Date.new(response_data['birth_year'],response_data['birth_month'],response_data['birth_day']).to_time.to_i  
    attr = {}
    attr["nickname"]        = response_data["nick"]
    attr["username"]        = response_data["name"]
    attr["gender"]          = response_data["sex"] == 2 ? 1 : 0
    attr["birthday"]        = [birthday,birthday]
    attr.each do |k,v|
      self.user.write_sample_attribute(k,v)
    end
  end

end
