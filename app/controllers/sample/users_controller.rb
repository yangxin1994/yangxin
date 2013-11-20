# coding: utf-8
class Sample::UsersController < Sample::SampleController
  layout :resolve_layout

  before_filter :require_sign_in, :except => [:change_email,:change_email_verify_key]
  before_filter :get_self_extend_info, :except => [:survey_detail, :spread_counter, 
                                      :update_logistic_address, :update_password, 
                                      :destroy_notification, :remove_notifications,
                                      :unbind, :bind_share, :bind_subscribe, :update_basic_info,
                                      :change_mobile, :check_mobile_verify_code, :change_email, :change_email_verify_key]

  before_filter :setting_nav,:only => [:basic_info, :avatar, :update_avatar ,:bandings,:address, :password, :bindings, :reset_pass]
  before_filter :survey_nav,:only => [:join_surveys,:index, :spread_surveys, :survey_detail]
  before_filter :order_nav,:only => [:orders, :from_lottery, :from_point, :order_show]

  def get_mobile_area 
    @retval = QuillCommon::MobileUtility.region_and_carrier(params[:m])
    render :json => false and return if @retval["retmsg"].to_s != "OK"
    @retval = "#{@retval['city']}, 中国 #{@retval['carrier']}"
    render_json_auto @retval and return
  end
  
  def join_surveys
    @answers = current_user.answers.not_preview.desc(:created_at)
    @my_answer_surveys = auto_paginate @answers do |paginated_answers|
      paginated_answers.map { |a| a.append_reward_info }
    end
    respond_to do |format|
      format.html { render 'join_surveys' } # adapt to alias index action
      format.json { render_json_auto @my_answer_surveys }
    end
  end

  alias :index :join_surveys

  def spread_surveys
    @my_spread_surveys = auto_paginate current_user.survey_spreads.desc(:survey_creation_time)
    respond_to do |format|
      format.html 
      format.json { render_json_auto @my_spread_surveys }
    end
  end

  def survey_detail
    @survey = Survey.find_by_id(params[:id])
    @answers = @survey.answers.not_preview.where(:introducer_id => current_user._id.to_s).desc(:status)
    params[:per_page] = 9
    @answers = auto_paginate @answers  
    respond_to do |format|
      format.html {
        render :layout => false if request.headers["OJAX"]
      }
      format.json { render_json_auto @answers }
    end
  end

  def spread_counter
    @survey = Survey.find_by_id(params[:id])
    @answers = @survey.answers.not_preview.where(:introducer_id => current_user._id.to_s)
    @spreaded_answer_number = {
      "total_answer_number" => @answers.length,
      "finished_answer_number" => @answers.finished.length,
      "editting_answer_number" => @answers.where(:status => Answer::EDIT).length}
    render_json_auto @spreaded_answer_number
  end

  def points
    if params[:scope] == 'in'
      @point_logs = auto_paginate PointLog.where(:user_id => current_user.id, :amount.gt => 0).desc(:created_at)
    elsif params[:scope] == 'out' 
      @point_logs = auto_paginate PointLog.where(:user_id => current_user.id, :amount.lt => 0).desc(:created_at)
    else
      @point_logs = auto_paginate PointLog.where(:user_id => current_user.id).desc(:created_at)
    end
    respond_to do |format|
      format.html 
      format.json { render_json_auto @point_logs and return }
    end
  end

  def orders
    # scope = [1,2,4].include?(params[:scope].to_i) ? params[:scope].to_i : 1
    @orders = current_user.orders.where(:source => (params[:scope] || Order::WAIT).to_i).desc(:created_at)
    @orders = auto_paginate @orders   
    respond_to do |format|
      format.html 
      format.json { render_json_auto @orders and return }
    end
  end

  def order_detail
    @order = Order.find_by_id(params[:id])
    respond_to do |format|
      format.html {
        render :layout => false if request.headers["OJAX"]
      }
      format.json { render_json_auto @order, :only => [:success] and return }
    end
  end

  def order_cancel
    @order = Order.find_by_id(params[:order_id])
    @order.update_attributes(:status => Order::CANCEL,:canceled_at => Time.now)
    prev_point = @order.sample.point 
    @order.sample.update_attributes(:point => prev_point + @order.point)
    respond_to do |format|
      format.json{render_json_auto @order }
    end
  end

  def basic_info
    @user_info = current_user.get_basic_attributes
    %w{income_person income_family seniority}.each do |attr|
      @user_info[attr][0] = -99999999 if @user_info[attr].is_a?(Array) && @user_info[attr][0] == -1.0/0.0
      @user_info[attr][1] = 99999999 if @user_info[attr].is_a?(Array) && @user_info[attr][1] == 1.0/0.0
    end
  end

  def update_basic_info
    param_attrs = params[:attrs].select{|e| %w(nickname username gender birthday born_address 
                        live_address married children income_person income_family
                        education_level major industry position seniority).include?(e)}
    # remove blank attrs
    %w(nickname username).each do |item|
      param_attrs.delete item if param_attrs[item].to_s.blank?
    end
    %w(gender birthday born_address 
      live_address married children income_person income_family
      education_level major industry position seniority).each do |item|
      param_attrs.delete item if param_attrs[item].nil? || param_attrs[item].to_i == -1
    end
    # format attrs
    param_attrs["income_person"] = param_attrs["income_person"].split('_').collect!{|e| e.to_i } if param_attrs["income_person"]
    # change 99999999 to -1
    param_attrs["income_person"][1] = 1.0/0.0 if param_attrs["income_person"].is_a?(Array) and param_attrs["income_person"][1] == 99999999

    param_attrs["income_family"] = param_attrs["income_family"].split('_').collect!{|e| e.to_i} if param_attrs["income_family"]
    # change 99999999 to -1
    param_attrs["income_family"][1] = 1.0/0.0 if param_attrs["income_family"].is_a?(Array) and param_attrs["income_family"][1] == 99999999
    param_attrs["seniority"] = param_attrs["seniority"].split('_').collect!{|e| e.to_i} if param_attrs["seniority"]
    # change 99999999 to -1
    param_attrs["seniority"][1] = 1.0/0.0 if param_attrs["seniority"].is_a?(Array) and param_attrs["seniority"][1] == 99999999
    param_attrs["birthday"] = [param_attrs["birthday"].to_i, param_attrs["birthday"].to_i] if param_attrs["birthday"]    
    %w(gender born_address live_address married children education_level major industry position).each do |item|
      param_attrs[item] = param_attrs[item].to_i if param_attrs[item]
    end
    @retval = current_user.set_basic_attributes(param_attrs)

    respond_to do |format|
      format.html {
        redirect_to :action => :basic_info
      }
      format.json { render_json_auto @retval }
    end
  end

  def avatar
  end

  def update_avatar
    @update_retval = false
    if @current_user_info
      avatar = Avatar.new.set_and_store(@current_user_info['sample_id'], params[:crop], params[:avatar])
      @update_retval = true
    end
    render action: 'avatar'
  end

  def bindings
    @bindings = {}
    @bindings["email"] = [current_user.email, current_user.email_subscribe] if current_user.email_activation
    @bindings["mobile"] = [current_user.mobile, current_user.mobile_subscribe] if current_user.mobile_activation
    %w(sina renren qq tecent alipay qihu360).each do |website|
      tp_user = ThirdPartyUser.where(:user_id => current_user._id.to_s, :website => website).first
      @bindings[website] = [tp_user.nick, tp_user.share] if tp_user.present?
    end
  end

  def unbind
    tp_user = ThirdPartyUser.where(:website => params[:website], :user_id => current_user._id.to_s).first
    tp_user.destroy if !tp_user.nil?
    render_json_s and return
  end

  def bind_share
    tp_user = ThirdPartyUser.where(:website => params[:website], :user_id => current_user._id.to_s).first
    render_json_auto tp_user.update_attributes(share: params[:share].to_s == "true") and return
  end

  def bind_subscribe
    if params[:type] == "email" && current_user.email_activation
      render_json_auto current_user.update_attributes(email_subscribe: params[:sub].to_s == "true") and return
    end
    if params[:type] == "mobile" && current_user.mobile_activation
      render_json_auto current_user.update_attributes(mobile_subscribe: params[:sub].to_s == "true") and return
    end
  end

  def change_mobile
    render_json_e ErrorEnum::EMAIL_OR_MOBILE_EXIST and return if User.find_by_mobile(params[:m]).present?
    current_user.mobile_to_be_changed = params[:m]
    current_user.sms_verification_code = Tool.generate_active_mobile_code
    current_user.sms_verification_expiration_time = Time.now.to_i + 2.hours.to_i
    current_user.save
    SmsWorker.perform_async("change_mobile", params[:m], "", :code => current_user.sms_verification_code)
    render_json_s and return
  end

  def check_mobile_verify_code
    render_json_e ErrorEnum::MOBILE_NOT_EXIST and return if current_user.mobile_to_be_changed != params[:m]
    render_json_e ErrorEnum::ILLEGAL_ACTIVATE_KEY and return if current_user.sms_verification_code != params[:code]
    render_json_e ErrorEnum::ACTIVATE_EXPIRED if current_user.sms_verification_expiration_time < Time.now.to_i
    current_user.mobile = current_user.mobile_to_be_changed
    render_json_auto current_user.update_attributes(mobile_activation: true) and return
  end

  def change_email
    render_json_e ErrorEnum::EMAIL_OR_MOBILE_EXIST and return if !User.find_by_email(params[:email]).nil?
    current_user.email_to_be_changed = params[:email]
    current_user.change_email_expiration_time = Time.now.to_i + OOPSDATA[Rails.env]["activate_expiration_time"].to_i
    current_user.save
    EmailWorker.perform_async(
      "change_email",
      params[:email],
      "#{request.protocol}#{request.host_with_port}",
      "/users/setting/change_email_verify_key",
      :user_id => current_user._id.to_s)
    render_json_s and return
  end

  def change_email_verify_key
    activate_info = {}
    begin
      activate_info_json = Encryption.decrypt_activate_key(params[:key])
      activate_info = JSON.parse(activate_info_json)
    rescue
      @success = false
      return
    end
    user = User.find_by_id(activate_info["user_id"])
    if user.nil?
      @success = false
      return
    end
    retval = user.change_email(request.remote_ip)
    if retval == false
      @success = false
      return
    end
    refresh_session(retval['auth_key'])
    @success = true
  end

  def address
    @receiver_info = current_user.affiliated.try(:receiver_info) || {}
    respond_to do |format|
      format.html { }
      format.json { render_json_auto @receiver_info }
    end
  end

  def update_logistic_address
    @retval = current_user.set_receiver_info(params[:receiver_info])
    respond_to do |format|
      format.html { }
      format.json { render_json_auto @retval }
    end
  end

  def password 
  end

  def update_password
    @retval = current_user.reset_password(params[:old_password], params[:new_password])
    respond_to do |format|
      format.html { }
      format.json { render_json_auto(@retval) and return }
    end
  end

  def notifications
    @notices = auto_paginate current_user.messages    
    current_user.update_attributes(last_read_messeges_time: Time.now)
    respond_to do |format|
      format.html 
      format.json { render_json_auto @notices }
    end
  end

  def destroy_notification
    @message = Message.find(params[:id])
    render_json_auto @message.destroy and return
  end

  def remove_notifications
    @retval = current_user.messages.destroy_all
    respond_to do |format|
      format.html { }
      format.json { render_json_auto @retval and return }
    end
  end

  private
  def get_self_extend_info
    @bind_info = {}
    ["sina", "renren", "qq", "tecent", "renren", "alipay"].each do |website|
      @bind_info[website] = !ThirdPartyUser.where(:user_id => current_user._id.to_s, :website => website).blank?
    end
    @bind_info["email"] = current_user.email_activation
    @bind_info["mobile"] = current_user.mobile_activation
    @current_user_info = {
      "answer_number" => current_user.answers.not_preview.finished.length,
      "spread_number" => Answer.where(:introducer_id => current_user._id).not_preview.finished.length,
      "bind_info" => @bind_info,
      "completed_info" => current_user.completed_info,
      "point" => current_user.point,
      "sample_id" => current_user._id.to_s,
      "nickname" => current_user.nickname
    }
  end

  def setting_nav
    @current_nav = 'setting'  
  end

  def survey_nav
    @current_nav = 'surveys'  
  end

  def order_nav
    @current_nav = 'orders' 
  end

  def resolve_layout
    case action_name
    when "change_email_verify_key"
      "sample_account"
    else
      "sample"
    end
  end
end