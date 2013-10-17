class RenrenUser < ThirdPartyUser

  def self.save_tp_user(response_data,current_user)
    renren_user = RenrenUser.where(:website_id => response_data["user"]["id"]).first
    renren_user = RenrenUser.where(:user_id => current_user.id).first if current_user.present?
    u = current_user.present? ? current_user : User.new(:status => User::REGISTERED)
    unless renren_user.present?
      renren_user = RenrenUser.create(:website => "renren", 
        :website_id => response_data["user"]["id"], 
        :access_token => response_data["access_token"], 
        :refresh_token => response_data["refresh_token"], 
        :expires_in => response_data["expires_in"],
        :user_id => u.id
      )
      u.save unless current_user.present?
    end

    renren_user.update_user_info(response_data)

    return renren_user
  end


  def update_user_info(data)
    response_data = call_method(
      http_method: 'get',
      url: 'https://api.renren.com/v2/',
      action: 'user/get',
      opts: {
        access_token: self.access_token,
        userId: self.website_id
      }
    )
    
    response_data = response_data["response"]

    date_arr = response_data["basicInformation"]["birthday"].split('-').map!{|e| e.to_i}
    education_level = -1
    case response_data["education"][0]["educationBackground"]
    when 'COLLEGE'
      education_level = 2
    when 'MASTER'
      education_level = 3
    when 'DOCTOR'
      education_level = 4
    when 'TECHNICAL'
      education_level = 1
    when 'HIGHSCHOOL'
      education_level = 0
    end

    bd = Date.new(date_arr[0],date_arr[1],date_arr[2]).to_time.to_i
    attr = {}
    attr["nickname"]        = response_data["name"] unless self.user.read_sample_attribute('nickname').present? 
    attr["username"]        = response_data["name"] unless self.user.read_sample_attribute('username').present? 
    attr["gender"]          = response_data["basicInformation"]["sex"] == "MALE" ? 0 : 1   unless self.user.read_sample_attribute('gender').present? 
    attr["birthday"]        = [bd,bd] unless self.user.read_sample_attribute('birthday').present? 
    attr['education_level'] = education_level unless self.user.read_sample_attribute('education_level').present? 
    attr.each do |k,v|
      self.user.write_sample_attribute(k,v)
    end
    self.update_attributes(
      :nick => response_data["name"],
      :share => true,
      :website_id => data["user"]["id"],
      :access_token => data["access_token"], 
      :refresh_token => data["refresh_token"],
      :expires_in => data["expires_in"]
    )
  end

end
