# encoding: utf-8
require 'httparty'
class Admin::PopularizesController < Admin::AdminController
  before_filter :require_sign_in

  layout "layouts/admin-todc"

  #banner 相关
  def index
    @banners = auto_paginate Banner.all
  end

  def create  
    banner = Banner.new(params[:banner]) 
    current_user.banners << banner
    redirect_to :action => :index
  end

  def destroy
    banner = Banner.find_by_id(params[:id])
    if banner.destroy
      render_json_auto(true)
    end
  end

  def sort
    params[:ids].each_with_index do |bid,idx|
      banner = Banner.find_by_id(bid)
      if banner.present?
        banner.update_attributes(:pos => (idx + 1))
      end
    end
    render_json_auto(true)
  end

  # weibo 相关
  def weibo
    weibo_id = params[:weibo_id]
    page = params[:page] || 1
    @sina_user = SinaUser.find_by_user_id(current_user.id)
    @users = []
    if @sina_user.present?
      access_token = @sina_user.access_token
      if weibo_id.present?
        weibo_id = get_weibo_id(weibo_id,access_token)
        retval = HTTParty.get("https://api.weibo.com/2/statuses/repost_timeline.json?id=#{weibo_id.to_i}&access_token=#{access_token}&page=#{page}&count=200")
        body = JSON.parse(retval.body)
        if body.length > 0
          result = body['total_number'].to_i.divmod(199)
          if result[1] > 0
            get_count = result[0] + 1
          else
            get_count = result[0]
          end
          weibo_id_arr = []
          get_count.times do |n|
            data = HTTParty.get("https://api.weibo.com/2/statuses/repost_timeline.json?id=#{weibo_id.to_i}&access_token=#{access_token}&page=#{n+1}&count=200")
            data_body = JSON.parse(data.body)
            users = gegerate_user(data_body['reposts'])
            weibo_id_arr.push users
          end
          weibo_id_arr.flatten!
          weibo_id_arr.uniq!
          @users = get_users(weibo_id_arr)          
        end
      else
        if params[:success]
          @notice = '恭喜,操作已完成!'
        end  
      end
    end
    return @users
  end

  def add_reward
    if params[:user_ids].length > 0
      wrong_user_ids = []
      params[:user_ids].each do |user_id|
        user = User.find_by_id(user_id)
        point_recod = PointLog.where(:user_id => user.id,:reason => PointLog::ADMIN_OPERATE,:remark => /积分快来/).first
        if user.present? && !point_recod.present?
          point = 20
          if user.update_attributes(:point => point)
            PointLog.create_sina_reward_point_log(point,user.id)  
          else
            error_user_ids.push user.id
          end
        end
      end
      Message.create(:title => '《积分快来》奖励发放',:content => '尊敬的问卷吧用户,您参与微博活动《积分快来》获得20积分，已经发放到您的账户,感谢您的热心参与',:receiver_ids => ( params[:user_ids] - wrong_user_ids ) )
      render_json_auto wrong_user_ids
    end
  end
  

  #SinaUser.get_data('AqTw3uXGd','2.00xHMWAC0vE4PH3d73a95aedZakSvC')

  def get_data(weibo_id,access_token)
    weibo_id = get_weibo_id(weibo_id,access_token)
    retval = HTTParty.get("https://api.weibo.com/2/statuses/repost_timeline.json?id=#{weibo_id.to_i}&access_token=#{access_token}&page=1&count=200")
    body = JSON.parse(retval.body)
    if body.length > 0
      result = body['total_number'].to_i.divmod(199)
      if result[1] > 0
        get_count = result[0] + 1
      else
        get_count = result[0]
      end
      weibo_id_arr = []
      get_count.times do |n|
        data = HTTParty.get("https://api.weibo.com/2/statuses/repost_timeline.json?id=#{weibo_id.to_i}&access_token=#{access_token}&page=#{n+1}&count=200")
        data_body = JSON.parse(data.body)
        users = gegerate_user(data_body['reposts'])
        weibo_id_arr.push users
      end
      weibo_id_arr.flatten!
      weibo_id_arr.uniq!
      return weibo_id_arr.length
      @users = get_users(weibo_id_arr)          
    end    
  end

  private 
  def get_weibo_id(weibo_id,access_token)
    retval = HTTParty.get("https://api.weibo.com/2/statuses/queryid.json?mid=#{weibo_id}&type=1&isBase62=1&access_token=#{access_token}")
    body = JSON.parse(retval.body)
    return  body['id']
  end



  def gegerate_user(data_arr)
    user_ids = []
    if data_arr.length > 0
      data_arr.each do |detail|
        if detail['user'].present?
          user_ids.push detail['user']['id']  unless user_ids.include?(detail['user']['id'])
        end 
      end
    end
    return user_ids
  end

  def get_users(weibo_id_arr)
    users = []
    if weibo_id_arr.length > 0
      weibo_id_arr.each do |sina_user_id|
        sina_user = SinaUser.find_by_website_id(sina_user_id)
        if sina_user.present?
          user = sina_user.user
          users.push user if user.present?
        end         
      end
    end
    return users
  end
end
