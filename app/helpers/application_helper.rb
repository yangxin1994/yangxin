# encoding: utf-8
module ApplicationHelper

  def var_to_js
    vars = self.instance_variables.select do |var|
      # var.to_s[1] != '_' &&
      ![:@_config, :@_routes,
        :@_assigns, :@_controller, :@_request,
        :@view_renderer, :@view_flow,
        :@output_buffer, :@virtual_path,
        :@asset_paths, :@javascript_include,
        :@stylesheet_include].include? var
    end
    vars.map do |var|
      var_s = var.to_s
      var_s[0] = '_'
      "window.#{var_s} = #{raw self.instance_variable_get(var).to_json}"
    end.join(";\n").html_safe
  end

  def paginator_mini(paginator)
    render :partial => "admin/application/paginator_mini",  :locals => {
      :paginator => paginator
    }
  end

  def notice_auto
    return notice_failure(flash[:failure]) if flash[:failure]
    return notice_warning(flash[:warning]) if flash[:warning]
    return notice_success(flash[:success]) if flash[:success]
    return notice_information(flash[:info]) if flash[:info]
  end

  # ICP info
  # TODO: update
  def icp_info
    host = request.host.downcase
    if host.include? 'quillme'
      return '京 ICP 备 13048388 号'
    else
      return '京 ICP 备 13048388 号'
    end
  end

  # Copy right html
  def copyright_html
    return '版权所有 &copy; 2012-2014 问卷吧'
  end

  # Web site name
  def corp_name
    return '问卷吧'
  end
  
  def corp_name_short
    return '问卷吧'
  end

  def parent_layout(layout)
    @view_flow.set(:layout,output_buffer)
    self.output_buffer = render(:file => "layouts/#{layout}")
  end


  def ch_time(from_time)  
    time = time_ago_in_words(from_time,include_seconds = true)  
    time = time.sub(/about /,"")  
    time = time.sub(/over /,"")   
    if time.to_i == 0                 
      case time.to_s  
      when 'half a minute'   then '半分钟前'  
      when 'less than a minute' then '不到1分钟前'  
      when 'less than 5 seconds'   then '5秒前'  
      when 'less than 10 seconds' then '10秒前'  
      when 'less than 20 seconds' then '20秒前'  
      else time
      end  
    else  
      mun = time.to_i   
      case time[-3,3]  
      when 'nds'   then mun.to_s+'秒前'  
      when 'ute'   then mun.to_s+'分前'  
      when 'tes' then mun.to_s+'分钟前'  
      when 'urs','our' then mun.to_s+'小时前'  
      when 'day','ays' then mun.to_s+'天前'  
      when 'nth','ths' then mun.to_s+'个月前'  
      when 'ear','ars' then mun.to_s+'年前'  
      else time
      end  
    end 
  end

  def user_behavor(news)
    #username = %Q{<a href="#{user_path(news['user_id'])}">#{news['username']}</a>}.html_safe
    username = %Q{<span class="u">#{news['username']}</span>}.html_safe
    behavor  = ''
    result   = ''
    case news.type.to_i
    when 2
      if(news.result)
        #抽得了<a href="#{survey_path(news['prize_id'])}">#{news['prize_name']}</a>
        behavor = %Q{
          抽得了<a href="javascript:void(0);">#{news.prize_name}</a>
        }.html_safe        
      else
        behavor = %Q{
          参与了一次抽奖  
        }.html_safe
      end
    when 8
      case news.reason.to_i
      when 1
        if news.scheme_id.to_i > 0 
          behavor = %Q{
            回答了<a href="/s/#{(news.scheme_id)}">#{news.survey_title}</a>获得了<b>#{news.amount}</b>积分 
          }.html_safe 
        else
          behavor = %Q{
            回答了<a href="javascript:void(0);">#{news.survey_title}</a>获得了<b>#{news.amount}</b>积分   
          }.html_safe 
        end
      when 2
        ref = news.scheme_id.to_i > 0 ? "/s/#{news.scheme_id}" : "javascript:void(0);"
        if news.amount.to_i > 0
          behavor = %Q{
            推广了<a href="#{ref}">#{news.survey_title}</a>获得了<b>#{news.amount}</b>积分    
          }.html_safe
        else
          behavor = %Q{
            推广了<a href="#{ref}">#{news.survey_title}</a> 
          }.html_safe
        end
      when 4
        if news.gift_type.to_i == Gift::REAL.to_i
          behavor = %Q{
            使用<b>#{news.amount.abs}</b>积分兑换了<a href="/gifts/#{news.gift_id}">#{news.gift_name}</a>
          }.html_safe 
        else
          behavor = %Q{
            使用<b>#{news.amount.abs}</b>积分兑换了<span class="u">#{news.gift_name}</span>
          }.html_safe
        end           
      when 16
        behavor = %Q{
          违规操作,处罚了<b>#{news.amount.abs}</b>积分
        }.html_safe          
      when 32
        behavor = %Q{
          邀请样本答题,获得了<b>#{news.amount.abs}</b>积分
        }.html_safe  
      when 256
        behavor = %Q{
          从清研通导入<b>#{news.amount.abs}</b>积分
        }.html_safe             
      end
    when 16
      behavor = %Q{
        加入了问卷吧
      }.html_safe     end
    return username + behavor
  end


  def reward_type(type)
    reward = ''
    case type.to_i
    when 1
      reward = '元话费'
    when 2
      reward = '元支付宝转账'
    when 4
      reward = '优币'
    when 8
      reward = '抽奖机会'
    when 16
      reward = '个集分宝'
    end
    return reward 
  end


  def rounding(seconds)
    minutes = seconds.divmod(60).first
    seconds = seconds.divmod(60).last
    if minutes < 1
      return 1
    else
      if seconds <=30
        return minutes
      else
        return minutes + 1
      end
    end
  end

  def can_answer?(times)
    expire_time = Time.at(times)
    now         = Time.now
    balance     = expire_time - now
    if balance < 0
      return '已结束' 
    else
      mm,ss = balance.divmod(60)
      hh,mm = mm.divmod(60)
      dd,hh = hh.divmod(24)
      if dd > 0
        tmp = "%d天 %d小时 %d分钟 %d秒" % [dd,hh,mm,ss] 
      elsif hh > 0
        tmp = "%d小时 %d分钟 %d秒" % [hh,mm,ss] 
      elsif mm > 0
        tmp = "%d分钟 %d秒" % [mm,ss] 
      elsif ss > 0
        tmp = "%d秒" % [ss] 
      end
      return tmp + ' 后结束' 
    end
  end 

  def int_time_to_date(int_time)
    Time.at(int_time.to_i).strftime("%F")
  end

  def sample_paginator(items)
    url = request.url.split('?').first
    render :partial => "/sample/application/pagination", :locals => {:common => items, :path => url}      
  end

  def sample_paginator_ajax(items,status,reward_type,point)
    render :partial => "/sample/application/pagination_ajax", :locals => {:common => items,:sta => status,:reward => reward_type,:point => point}
  end

  def int_time_to_datetime(int_time)
    Time.at(int_time.to_i).strftime("%Y-%m-%d %H:%M:%S")
  end

  def order_next_node(order)
    case order.status.to_i
    when Order::WAIT
    '(预计在' + (DateTime.parse(order.created_at.strftime('%Y-%m-%d')) + 1.months).strftime('%Y年%-m月') + '5日前完成审核)' 
    when Order::HANDLE
      if order.type.to_i == Order::REAL 
        '(预计在' + (DateTime.parse(Time.at(order.handled_at).strftime("%Y-%m-%d")) + 1.months).strftime('%Y年%-m月') + '5日前送达)'
      else
        '(预计在' + (DateTime.parse(Time.at(order.handled_at).strftime("%Y-%m-%d")) + 1.months).strftime('%Y年%-m月') + '5日前支付)'
      end
         
    end
  end

  def answered?(status, reject_type=0, free_reward=false,survey=nil)
    case status.to_i
    when Answer::EDIT
      return "<a href='/s/#{survey.scheme_id}'>答题中</a>" if survey.present?
      return "答题中" unless survey.present?
    when Answer::REJECT
      case reject_type.to_i
      when 0
        return "被拒绝"
      when Answer::REJECT_BY_QUOTA
        return "配额拒绝"
      when Answer::REJECT_BY_QUALITY_CONTROL
        return "质控拒绝"
      when Answer::REJECT_BY_REVIEW, Answer::REJECT_BY_AGENT_REVIEW
        return "已完成" if free_reward
        return "审核拒绝"
      when Answer::REJECT_BY_SCREEN
        return "甄别拒绝"
      when Answer::REJECT_BY_TIMEOUT
        return "超时拒绝"
      when Answer::REJECT_BY_IP_RESTRICT
        return "IP拒绝"
      when Answer::REJECT_BY_ADMIN
        return "管理员拒绝"
      else
        return reject_type.to_s
      end
    when Answer::UNDER_REVIEW, Answer::UNDER_AGENT_REVIEW
      return "已完成" if free_reward
      return "<span class='c-red'>待审核</span>"
    when Answer::FINISH
      return "已完成"
    when Answer::REDO
      return "需重答"
    else
      #return status
      return '待参与' unless survey.present?
      return "<a href='/s/#{survey.scheme_id}'>待参与</a>" if survey.present?
    end
  end

  # In my spread_surveys page
  def survey_type?(type)
    case type.to_i 
    when 0
      return "免费调研"
    when 1,2,16
      return "现金调研"
    when 4
      return "积分调研"
    when 8
      return "抽奖调研"
    end
  end

  # 
  # * version:
  # thumb: 104x104
  # small: 36x36
  # mini: 20x20
  # 
  def get_avatar(user_id, version="thumb")
    md5 = Digest::MD5.hexdigest(user_id)  if user_id.present?
    return "/uploads/avatar/#{version}_#{md5}.png" if File.exist?("#{Rails.root}/public/uploads/avatar/#{version}_#{md5}.png")
    avatar = nil
    %w( mini small thumb).each do |ver|     
      if File.exist?("#{Rails.root}/public/uploads/avatar/#{ver}_#{md5}.png")
        avatar =  "/uploads/avatar/#{ver}_#{md5}.png"   
        break
      end
    end
      
    if avatar.present?
      return avatar 
    else
      return "/assets/avatar/#{version}_default.png"
    end 
  end

  def thumb_avatar(user_id)
    get_avatar(user_id)
  end

  def small_avatar(user_id)       
    get_avatar(user_id, 'small')        
  end

  def mini_avatar(user_id)
    get_avatar(user_id, 'mini')
  end

  def hide_border?(arr,index)
    sty = "style=border-bottom:none"  if index.to_i == (arr.length - 1)
  end
  # 
  # Order ***********
  # 

  # Status

  def order_status(int_status)
    case int_status.to_i
    when Order::WAIT
      return "等待处理"
    when Order::HANDLE
      return "正在处理"
    when Order::SUCCESS
      return "订单完成"
    when Order::FAIL
      return "处理失败"
    when Order::CANCEL
      return "撤消订单"
    when Order::FROZEN
      return "等待审核"
    when Order::REJECT
      return "未通过审核"
    else
      return int_status.to_s    
    end
  end

  def order_list(int_status, int_step=1)
    # int_step: 1, 2
    retval = ""
    case int_status.to_i
    when Order::MOBILE_CHARGE, Order::SMALL_MOBILE_CHARGE
      if int_step.to_i == 1
        retval = "准备充值中"
      else
        retval = "充值成功，请注意查收"
      end
    when Order::ALIPAY
      if int_step.to_i == 1
        retval = "准备转账中"
      else
        retval = "转账成功，请注意查收"
      end   
    when Order::REAL
      if int_step.to_i == 1
        retval = "正在安排配送"
      else
        retval = "礼品已经发出，请注意查收"
      end
    else
      if int_step.to_i == 1
        retval = "正在处理"
      else
        retval = "订单处理成功"
      end
    end
    return retval
  end

  def order_process(int_status)
    retval = ""
    case int_status.to_i
    when Order::QQ_COIN, Order::JIFENBAO
      retval = "运营商处理"
    when Order::ALIPAY
      retval = "安排转账"
    when Order::MOBILE_CHARGE, Order::SMALL_MOBILE_CHARGE
      retval = "安排充值"
    when Order::REAL
      retval = "安排配送" 
    else
      retval = "正在处理"
    end
    return retval
  end

  def change_point_reason_type(int_type)
    retval = ""
    case int_type.to_i
    when PointLog::ANSWER
      retval = "答题奖励"
    when PointLog::SPREAD
      retval = "推广问卷"
    when PointLog::REDEEM
      retval = "礼品兑换"
    when PointLog::ADMIN_OPERATE
      retval = "管理员操作"
    when PointLog::PUNISH
      retval = "处罚操作" 
    when PointLog::INVITE_USER
      retval = "邀请样本"
    when PointLog::REVOKE
      retval = "撤销订单"
    when PointLog::IMPORT
      retval = "原有系统导入" 
    when PointLog::NETRANKING_IMPORT
      retval = "清研通导入" 
    end
    return retval
  end

  def survey_status(int_status)
    int_status = int_status.to_i
    retval = ""
    case int_status
    when 1
      retval = "关闭"
    when 2
      retval = "发布"
    when 4   
      retval = "已删除"
    end
  end

  def current_tab?(status,param)
    if status.to_s == param.to_s
      return 'current'
    end
  end

  def selected?(value,params)
    if value.to_s == params.to_s
      return "selected=selected"
    end
  end

  def show_image(image_path,type)
    if(!File.exists?(Rails.public_path + image_path.to_s))
      case type.to_s
      when 'avatar'
        return '/assets/avatar/small_default.png'
      when 'gifts','prizes'
        return '/assets/od-quillme/gifts/default.png'
      end
      return '/assets/od-quillme/gifts/default.png'
    else
      return image_path
    end
  end

  def show_gift_price(price)
    return price.to_s.split('.').first
  end

  def show_default_select_option(answer_status,nav_status)
    case answer_status.to_s
    when "0"
      if nav_status.to_s == '1'
        current_option = %Q{
          <span class="select-txt" data="0">未参与</span>
        }.html_safe
      else
        current_option = %Q{
          <span class="select-txt" data="0">待参与</span>
        }.html_safe 
      end
        
    when "1"
      current_option = %Q{
      <span class="select-txt" data="1">答题中</span>
    }.html_safe 
    when "2"
      current_option = %Q{
      <span class="select-txt" data="2">被拒绝</span>
    }.html_safe 
    when "4,8"
      current_option = %Q{
      <span class="select-txt" data="4,8">待审核</span>
    }.html_safe 
    when "32"
      current_option = %Q{
      <span class="select-txt" data="32">已完成</span>
    }.html_safe 
    else
      current_option = %Q{
      <span class="select-txt" data="">所有问卷</span>
    }.html_safe 
    end
    return current_option
  end

  def opend_nav?(status)
    opend = status.to_s == '1' ? false : true
  end
  
  # used in user-center
  def small_gift_image(img_path)
    return "/assets/od-quillme/uc/gift_36X36.png" if img_path.to_s.empty? || !File.exist?("#{Rails.root}/public#{img_path}")
    return img_path
  end

  def interviewer_format(status)
    #0(doing), 1(under review), 2(finished)
    case status.to_i
    when 0
      return '正在进行'
    when 1
      return '正在审核'
    when 2
      return '已经完成'
    end
  end 

end
