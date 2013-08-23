# -*- encoding: utf-8 -*-
require 'core/nil_class'
require 'core/string'
class ApplicationController < ActionController::Base
  protect_from_forgery

  layout 'quill'

  before_filter :init, :current_user, :current_sample_info
  helper_method :user_signed_in, :user_id, :email, :mobile, :unread_message_count, :is_admin, :social_auth_link

  # init action
  def init
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
      if result != ErrorEnum::AUTH_KEY_NOT_EXIST
        # If auth_key is valid. Setup user session and return true
        cookies[:auth_key] = {
          :value => auth_key,
          :expires => (result['expire_at'] < 0 ? Rails.application.config.permanent_signed_in_months.months.from_now : nil),
          :domain => :all
        }
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

    cookies.delete(:auth_key, :domain => :all)
    reset_session
    return false
  end

  def current_user
    @current_user = session[:auth_key].nil? ? nil : User.find_by_auth_key(session[:auth_key])
    return @current_user
  end

  def render_json(is_success = true, &block)
    @is_success = is_success.present?
    render :json => {
                :value => block_given? ? yield(is_success) : is_success ,
                :success => @is_success
              }
  end
  def return_json(is_success, value, options = {})
    options[:only] = options[:only].to_a + [:success, :value] if options[:only]
    render :json => {
        :success => is_success,
        :value => value
      },
      :except => options[:except], 
      :only => options[:only]
  end
  def render_json_e(error_code)
    error_code_obj = {
      :error_code => error_code,
      :error_message => ""
    }
    return_json(false, error_code_obj)
  end
  def render_json_s(value = true, options={})
    return_json(true, value, options)
  end
  def render_json_auto(value = true, options={})
    is_success = !((value.class == String && value.start_with?('error_')) || value.to_s.to_i < 0)
    is_success ? render_json_s(value, options) : render_json_e(value)
  end

  def success_true(_is = true)
    @is_success = _is
  end

  def session_info
    return Common::SessionInfo.new(session[:auth_key], request.remote_ip)
  end

  def has_role(role)
    if (session[:status].to_i == User::VISITOR || session[:role].nil?) 
      return false
    else
      return ((session[:role].to_i & role) > 0)
    end
  end
  def is_admin
    return has_role(User::ADMIN)
  end
  def user_signed_in
    return !!@current_user && @current_user.status == User::REGISTERED
    # return has_role(User::SAMPLE) || has_role(User::CLIENT)
  end
  def email
    return @current_user.try(:email)
  end
  def mobile
    return @current_user.try(:mobile)
  end
  def user_id
    return @current_user.nil? ? nil : @current_user._id.to_s
  end
  def unread_message_count
    return @current_user.try(:unread_messages_count).to_i
  end

  def current_sample_info
    return if @current_user.nil?

    # answer number, spread number, third party accounts
    answer_number = @current_user.answers.not_preview.finished.length
    spread_number = Answer.where(:introducer_id => @current_user._id).not_preview.finished.length
    bind_info = {}
    ["sina", "renren", "qq", "google", "kaixin001", "douban", "baidu", "sohu", "qihu360"].each do |website|
      bind_info[website] = !ThirdPartyUser.where(:user_id => @current_user._id.to_s, :website => website).blank?
    end
    bind_info["email"] = @current_user.email_activation
    bind_info["mobile"] = @current_user.mobile_activation

    completed_info = @current_user.completed_info
    
    @current_sample = {
      "answer_number" => answer_number,
      "spread_number" => spread_number,
      "bind_info" => bind_info,
      "completed_info" => completed_info,
      "point" => @current_user.point,
      "sample_id" => @current_user._id.to_s,
      "nickname" => @current_user.nickname
    }

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
