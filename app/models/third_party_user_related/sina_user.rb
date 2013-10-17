class SinaUser < ThirdPartyUser

  def self.save_tp_user(response_data,current_user)
    sina_user = SinaUser.where(:website_id => response_data["uid"]).first
    u = current_user.present? ? current_user : User.new(:status => User::REGISTERED)
    unless sina_user.present?  # create binding
      sina_user = SinaUser.create(:website => "sina", :website_id => response_data["uid"], :user_id => u.id,:access_token => response_data["access_token"])
      u.save unless current_user.present?
    else
      unless sina_user.user.present?
        sina_user.update_attributes(:user_id => u.id)  # create binding
        u.save unless current_user.present?
      else
        sina_user.update_attributes(:user_id => u.id)  if  current_user.present?  #update binding
      end
    end

    sina_user.update_user_info

    return sina_user
  end


  def update_user_info

    response_data = call_method(
      http_method: 'get',
      format:'.json',
      url: 'https://api.weibo.com/2/',
      action: 'users/show',
      opts: {
        uid: self.website_id,
        access_token:self.access_token 
      }
    )

    gender = response_data["gender"] == 'm' ? 0 : 1
    attr = {"nickname" => response_data["screen_name"],"username" => response_data["screen_name"],"gender" => gender }
    attr.each do |k,v|
      self.user.write_sample_attribute(k,v)
    end
  end

end
