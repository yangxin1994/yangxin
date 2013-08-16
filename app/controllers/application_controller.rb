# -*- encoding: utf-8 -*-

class ApplicationController < ActionController::Base
  protect_from_forgery

  layout 'quill'

  before_filter :init,:current_sample_info
  helper_method :user_signed_in, :user_id, :email, :mobile, :unread_message_count, :is_admin, :social_auth_link

  # init action
  def init
    # get request referer
    # begin
    #   if !request.referer.blank?
    #     ref_uri = URI.parse(request.referer)
    #     if !ref_uri.host.downcase.end_with?(request.domain.downcase)
    #       session[:referer] = ref_uri.host.downcase
    #     end
    #   end
    # rescue => ex
    #   logger.debug ex
    # end

    # Use param value to override cookies value
    refresh_session(params[:auth_key] || cookies[:auth_key])
  end

  # =============================
  # Refresh user session using an auth_key
  # A user session is composed by:
  # 1. cookie: auth_key, guest_key.
  #    After refresh_session, if !cookie.auth_key.blank?, cookie.auth_key must be a valid user in Quill (user or guest).
  #    After refresh_session, if cookie.auth_key.blank?, cookie.guest_key msut be empty too.
  #    After refresh_session, if cookie.auth_key == cookie.guest_key and they are both not empty. It means the user is a guest
  # 2. session: auth_key (auth_key cache for Quill. Equal to cookie auth_key), role, status
  #    After refresh_session, session.auth_key == cookie.auth_key. And session.role logs the role of current user
  # =============================

  def refresh_session(auth_key)

    # 1. If auth_key is not empty. Check auth_key
    if !auth_key.blank?

      # 1.1. If auth_key is equal to session's value.
      #      It means that the current user session is for this auth_key. We just return true.
      if session[:auth_key] == auth_key
        # Q: What if cookie.auth_key is not equal to session.auth_key?
        # A: It will never happen. Because we set cookie.auth_key and session.auth_key the same value in 1.2 and
        #    never change them otherwhere.
        return true
      end

      # 1.2. If auth_key is not equal to session's value.
      #      It means we should check the auth_key with Quill. And refresh the current user session
      result = User.login_with_auth_key(auth_key)
      if result
        # If auth_key is valid. Setup user session and return true
        cookies[:auth_key] = {
          :value => auth_key,
          :expires => (result['expire_at'] < 0 ? Rails.application.config.permanent_signed_in_months.months.from_now : nil),
          :domain => :all
        }
        if !cookies[:guest_key].blank?
          cookies[:guest_key] = {
            :value => cookies[:guest_key],
            :expires => Rails.application.config.permanent_signed_in_months.months.from_now,
            :domain => :all
          }
        end
        session[:auth_key] = auth_key
        session[:role] = result['role']
        session[:status] = result['status']
        session[:email] = result['email']
        session[:mobile] = result['mobile']
        session[:user_id] = result['user_id']
        #result = Account::MessageClient.new(session_info).unread_count
        session[:unread_message_count] = current_user.unread_messages_count
        return true
      end
    end

    # 2. If auth_key is empty or not valid, and guest_key is not empty and is not equal to auth_key
    #    Try using guest_key to refresh session instead
    if !cookies[:guest_key].blank? && cookies[:guest_key] != auth_key
      return refresh_session(cookies[:guest_key])
    end

    # 3. If both auth_key and guest_key is not valid, destroy session and return false
    cookies.delete(:auth_key, :domain => :all)
    cookies.delete(:guest_key, :domain => :all)
    reset_session
    return false

  end

  def current_user
    @current_user = session[:auth_key].nil? ? nil : User.find_by_auth_key(session[:auth_key])
    return @current_user
  end

  def render_json(is_success = true, options = {}, &block)
    options[:only]+= [:value, :success] unless options[:only].nil?
    @is_success = is_success
    render :json => {:value => block_given? ? yield(@is_success) : @is_success ,
                     :success => @is_success
    }, :except => options[:except], :only => options[:only]   
  end

  def success_true
    @is_success = true
  end

  def session_info
    return Common::SessionInfo.new(session[:auth_key], request.remote_ip)
  end

  def has_role(role)
    if (session[:status].to_i == QuillCommon::UserStatusEnum::VISITOR || session[:role].nil?) 
      return false
    else
      return ((session[:role].to_i & role) > 0)
    end
  end
  def is_admin
    return has_role(QuillCommon::UserRoleEnum::ADMIN)
  end
  def user_signed_in
    return has_role(QuillCommon::UserRoleEnum::SAMPLE) || has_role(QuillCommon::UserRoleEnum::CLIENT)
  end
  def email
    return session[:email]
  end
  def mobile
    return session[:mobile]
  end
  def user_id
    return session[:user_id]
  end
  def unread_message_count
    return session[:unread_message_count].blank? ? 0 : session[:unread_message_count]
  end

  # def current_user_info
  #   user_info = nil
  #   result = Account::UserClient.new(session_info).get_basic_info
  #   if result.success
  #     user_info = {}
  #     %w[address alipay_account bank bankcard_number birthday full_name identity_card phone postcode].each do |attr_name|
  #       user_info[attr_name] = result.value[attr_name]
  #     end
  #   end
  #   return user_info
  # end


  def current_sample_info
    # @current_sample = Sample::UserClient.new(session_info).get_basic_info
    # @current_sample = @current_sample.value
    # result = Sample::UserClient.new(session_info).get_basic_info  unless session[:current_sample].present?
    # session[:current_sample]  ||= result.value
    # return session[:current_sample]   
  end 

  def auto_paginate(value, count = nil)
    retval = {}
    retval["current_page"] = page
    retval["per_page"] = per_page
    retval["previous_page"] = (page - 1 > 0 ? page-1 : 1)
    # retval["previous_page"] = [page - 1, 1].max

    # 当没有block或者传入的是一个mongoid集合对象时就自动分页
    # TODO : 更优的判断是否mongoid对象?
    # instance_of?(Mongoid::Criteria) .by lcm
    # if block_given? 
      if value.methods.include? :page
        count ||= value.count
        value = value.page(retval["current_page"]).per(retval["per_page"])
      elsif value.is_a?(Array) and value.count > per_page
        count ||= value.count
        value = value.slice((page-1)*per_page, per_page)
      end
      
        if block_given?
          retval["data"] = yield(value) 
        else
          retval["data"] = value
        end
    # else
    #   #retval["data"] = eval(value + '.page(retval["current_page"]).per(retval["per_page"])' )
    #   retval["data"] = value.page(retval["current_page"]).per(retval["per_page"])
    # end
    retval["total_page"] = ( (count || value.count )/ per_page.to_f ).ceil
    retval["total_page"] = retval["total_page"] == 0 ? 1 : retval["total_page"]
    retval["next_page"] = (page+1 <= retval["total_page"] ? page+1: retval["total_page"])
    # retval["next_page"] = [page + 1, retval["total_page"]].min
    retval
  end



  def application_name
    host = request.host.downcase
    if host.include? 'admin'
      return 'admin'
    elsif host.include?('quillme') || host.include?('oopsdata.cn')
      return 'quillme'
    else
      return 'quill'
    end
  end

  def render_404
    # render :text => "404"
    raise ActionController::RoutingError.new('Not Found')
  end
  
  def render_500
    raise '500 exception'
  end

  # sign out
  def _sign_out(ref = nil)
    refresh_session(nil)
    redirect_to ref.nil? ? root_path : ref
  end

  # require that the user should sign in before request thie action
  def require_sign_in
    #TODO: if Quill web says that user is signed. Ask quill again
    if !user_signed_in
      respond_to do |format|
        format.html { redirect_to sign_in_path({ref: request.url}) and return }
        format.json { render :json => Common::ResultInfo.error_require_login and return }
      end
    end
  end
  def require_sign_out
    _sign_out(request.url) if user_signed_in
  end

  # =============================
  # Social redirect uri
  # =============================
  def social_redirect_uri(website)
    intro = params[:i].blank? ? '' : "?i=#{params[:i]}"
    return "#{request.protocol}#{request.host_with_port}#{connect_path(website)}#{intro}"
  end
  def social_auth_link(website)
    redirect_uri = social_redirect_uri(website)
    client_id = Rails.application.config.authkeys[website.to_sym]
    case website
    when 'sina'
      return "https://api.weibo.com/oauth2/authorize?client_id=#{client_id}&response_type=code&redirect_uri=#{redirect_uri}&display=page"
    when 'renren'
      return "https://graph.renren.com/oauth/authorize?client_id=#{client_id}&response_type=code&redirect_uri=#{redirect_uri}&response_type=code&scope=publish_share+operate_like"
    when 'qq'
      return "https://graph.qq.com/oauth2.0/authorize?response_type=code&client_id=#{client_id}&redirect_uri=#{redirect_uri}"
    when 'google'
      return "https://accounts.google.com/o/oauth2/auth?response_type=code&client_id=#{client_id}.apps.googleusercontent.com&redirect_uri=#{redirect_uri}&scope=https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/userinfo.email"
    when 'qihu360'
      return "https://openapi.360.cn/oauth2/authorize?client_id=#{client_id}&response_type=code&redirect_uri=#{redirect_uri}"
    when 'kaixin001'
      return "http://api.kaixin001.com/oauth2/authorize?response_type=code&client_id=#{client_id}&redirect_uri=#{redirect_uri}"
    when 'douban'
      return "https://www.douban.com/service/auth2/auth?response_type=code&client_id=#{client_id}&redirect_uri=#{redirect_uri}"
    when 'baidu'
      return "https://openapi.baidu.com/oauth/2.0/authorize?response_type=code&client_id=#{client_id}&redirect_uri=#{redirect_uri}"
    when 'sohu'
      return "https://api.sohu.com/oauth2/authorize?response_type=code&client_id=#{client_id}&redirect_uri=#{redirect_uri}"
    end
  end

  # =============================
  # paging operate
  # =============================
  def slice(arr, page, per_page)
    return [] if !arr.instance_of?(Array)

    page = page.nil? || page.to_s.empty? ? 1 : page.to_i
    per_page = per_page.nil? || per_page.to_s.empty? ? 10 : per_page.to_i
    return [] if page < 1 || per_page < 1

    ### sort
    if arr.count > 1 && arr[0].respond_to?(:updated_at) then
      arr.sort!{|v1, v2| v2.updated_at <=> v1.updated_at}
    end

    # avoid arr = nil
    arr = arr.slice((page-1)*per_page, per_page) || []
    return arr
  end

  def page
    params[:page].to_i == 0 ? 1 : params[:page].to_i
  rescue
    1
  end

  def per_page
    params[:per_page].to_i == 0 ? 10 : params[:per_page].to_i
  rescue
    10
  end

  def self.def_each(*method_names, &block)
    method_names.each do |method_name|
      define_method method_name do
        instance_exec method_name, &block
      end
    end
  end

end
