require 'httparty'
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
        uid: data["uid"],
        access_token:data["access_token"] 
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


# #-----------------------------------------
#   def self.get_data(weibo_id,access_token)
#     weibo_id = get_weibo_id(weibo_id,access_token)
#     retval = HTTParty.get("https://api.weibo.com/2/statuses/repost_timeline.json?id=#{weibo_id.to_i}&access_token=#{access_token}&page=1&count=200")
#     body = JSON.parse(retval.body)
#     if body.length > 0
#       puts body['total_number']
#       puts '------------------------'
#       result = body['total_number'].to_i.divmod(199)
#       if result[1] > 0
#         get_count = result[0] + 1
#       else
#         get_count = result[0]
#       end
#       weibo_id_arr = []
#       get_count.times do |n|
#         puts n + 1
#         puts '!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
#         data = HTTParty.get("https://api.weibo.com/2/statuses/repost_timeline.json?id=#{weibo_id.to_i}&access_token=#{access_token}&page=#{n+1}&count=200")
#         data_body = JSON.parse(data.body)
#         users = gegerate_user(data_body['reposts'])
#         weibo_id_arr.push users
#       end
#       weibo_id_arr.flatten!
#       weibo_id_arr.uniq!
#       puts weibo_id_arr.length 
#       puts '==========================='
#       #return weibo_id_arr.length
#       @users = get_users(weibo_id_arr)
#       return @users.length          
#     end    
#   end

  
#   def self.get_weibo_id(weibo_id,access_token)
#     retval = HTTParty.get("https://api.weibo.com/2/statuses/queryid.json?mid=#{weibo_id}&type=1&isBase62=1&access_token=#{access_token}")
#     body = JSON.parse(retval.body)
#     return  body['id']
#   end



#   def self.gegerate_user(data_arr)
#     user_ids = []
#     if data_arr.length > 0
#       data_arr.each do |detail|
#         if detail['user'].present?
#           user_ids.push detail['user']['id']  unless user_ids.include?(detail['user']['id'])
#         end 
#       end
#     end
#     return user_ids
#   end

#   def self.get_users(weibo_id_arr)
#     users = []
#     if weibo_id_arr.length > 0
#       weibo_id_arr.each do |sina_user_id|
#         sina_user = SinaUser.find_by_website_id(sina_user_id)
#         if sina_user.present?
#           user = sina_user.user
#           users.push user if user.present?
#         end         
#       end
#     end
#     return users
#   end





end
