class SinaUser < ThirdPartyUser

  def self.save_tp_user(response_data,current_user)
    sina_user = SinaUser.where(:website_id => response_data["uid"]).first
    sina_user = SinaUser.where(:user_id => current_user.id).first if current_user.present?
    u = current_user.present? ? current_user : User.new(:status => User::REGISTERED)
    unless sina_user.present?  # create binding
      sina_user = SinaUser.create(
        :website => "sina", 
        :website_id => response_data["uid"], 
        :user_id => u.id,
        :access_token => response_data["access_token"]
      )
      u.save unless current_user.present?
    end

    sina_user.update_user_info(response_data)

    return sina_user
  end


  def update_user_info(data)

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

    attr = {}
    attr["nickname"]        = response_data["screen_name"] unless self.user.read_sample_attribute('nickname').present? 
    attr["username"]        = response_data["screen_name"] unless self.user.read_sample_attribute('username').present?
    attr["gender"]          = gender  unless self.user.read_sample_attribute('gender').present?
    attr.each do |k,v|
      self.user.write_sample_attribute(k,v)
    end
    response_data["screen_name"] ||= self.nick 
    self.update_attributes(
      :nick => response_data["screen_name"],
      :website_id => data["uid"], 
      :access_token => data["access_token"],
      :share => true
    )
  end

end
