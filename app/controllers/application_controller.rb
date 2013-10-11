# -*- encoding: utf-8 -*-
require 'core/nil_class'
require 'core/string'
class ApplicationController < ActionController::Base
  protect_from_forgery

  layout 'quill'

  attr_reader :current_user

  before_filter :init
  helper_method :user_signed_in, :current_user, :social_auth_link

  # init action
  def init
    # Use param value to override cookies value
    # _flashes = flash.instance_variable_get('@flashes').dup
    refresh_session(params[:auth_key] || cookies[:auth_key])
    # flash.instance_variable_set('@flashes', _flashes)
  end

  # =============================
  # Get current user and refresh a user's status by setting cookies or deleting cookies
  # Used when: 1. after sign in, 2. after sign out, 3. after active user and auto signin ...
  # =============================
  def refresh_session(auth_key)
    # 1. get current user
    @current_user = auth_key.blank? ? nil : User.find_by_auth_key(auth_key)
    if !current_user.nil?
      # If current user is not empty, set cookie
      cookies[:auth_key] = {
        :value => auth_key,
        :expires => Rails.application.config.permanent_signed_in_months.months.from_now,
        :domain => :all
      }
      return true
    else
      # If current user is empty, delete cookie
      cookies.delete(:auth_key, :domain => :all)
      return false
    end
  end
  def user_signed_in
    return !!current_user && current_user.status == User::REGISTERED
  end
  def require_sign_in
    if !user_signed_in
      respond_to do |format|
        format.html { redirect_to sign_in_account_path({ref: request.url}) and return }
        # format.json { render :json => Common::ResultInfo.error_require_login and return }
        format.json { render_json_e ErrorEnum::REQUIRE_LOGIN and return }
      end
    end
  end
  # sign out
  def _sign_out(ref = nil)
    refresh_session(nil)
    redirect_to ref.nil? ? root_path : ref
  end
  def require_sign_out
    _sign_out(request.url) if user_signed_in
  end

  # =============================
  # Render JSON
  # =============================
  def render_json(is_success = true, &block)
    @is_success = is_success.present?
    render :json => {
                :value => block_given? ? yield(is_success) : is_success ,
                :success => !!@is_success
              }
  end
  def render_json_e(error_code)
    error_code_obj = {
      :error_code => error_code,
      :error_message => ""
    }
    render_json false do 
      error_code_obj
    end
  end
  def render_json_s(value = true, options={})
    render_json true do 
      value
    end
  end
  def render_json_auto(value = true, options={})
    is_success = !((value.class == String && value.start_with?('error_')) || value.to_s.to_i < 0)
    is_success ? render_json_s(value, options) : render_json_e(value)
  end
  def render_404
    raise ActionController::RoutingError.new('Not Found')
  end
  def render_500
    raise '500 exception'
  end

  def success_true(_is = true)
    @is_success = _is
  end

  def fresh_when(opts = {})
    opts[:etag] ||= []
    # 保证 etag 参数是 Array 类型
    opts[:etag] = [opts[:etag]] if !opts[:etag].is_a?(Array)
    # 加入页面上直接调用的信息用于组合 etag
    opts[:etag] << current_user
    # 所有 etag 保持一天
    opts[:etag] << Date.current
    super(opts)
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
    client_id = OOPSDATA[Rails.env]["#{website}_app_key"]
    #client_id = Rails.application.config.authkeys[website.to_sym]
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

  def auto_paginate(value, count = nil)
    retval = {}
    retval["current_page"] = page
    retval["per_page"] = per_page
    retval["previous_page"] = (page - 1 > 0 ? page - 1 : 1)
    # retval["previous_page"] = [page - 1, 1].max

    # 当没有block或者传入的是一个mongoid集合对象时就自动分页
    # TODO : 更优的判断是否mongoid对象?
    # instance_of?(Mongoid::Criteria) .by lcm
    # if block_given? 
      if value.methods.include? :page
        count ||= value.count
        value = value.page(retval["current_page"]).per(retval["per_page"])
      elsif value.is_a?(Array) && value.count > per_page
        count ||= value.count
        value = value.slice((page - 1) * per_page, per_page)
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
end
