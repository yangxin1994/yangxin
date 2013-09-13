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
  before_filter :point_nav,:only => [:points]
  before_filter :order_nav,:only => [:orders, :from_lottery, :from_point, :order_show]
  before_filter :job_nav, :only => [:jobs]
  before_filter :notification_nav, :only => [:notifications]


  def initialize
    super('users')
  end

  def get_mobile_area 
    @retval = QuillCommon::MobileUtility.region_and_carrier(params[:m])
    render :json => false and return if @retval["retmsg"].to_s != "OK"
    @retval = "#{@retval['city']}, 中国 #{@retval['carrier']}"
    render_json_auto @retval and return
  end

  # *********************************
  # ============Different Partial of User Center Page==============================

  # ************ surveys *********************

  # 我参加的调研
  # GET
  def join_surveys
    @answers = current_user.answers.not_preview.desc(:created_at)
    @my_answer_surveys = auto_paginate @answers do |paginate_answers|
      paginate_answers.map { |e| e.info_for_answer_list_for_sample }
    end


    # @my_answer_surveys = @uclient.get_my_surveys(page, per_page)

    data = @my_answer_surveys['data'].map do |item |
      # Need attrs: rewards, answer_status, answer_id, amount
      # maybe it has too many attrs, so i did not use helper method.

      # select reward
      item["select_reward"] = ""
      # 
      item["free_reward"] = item["rewards"].to_a.empty?
      item["rewards"].to_a.each do |rew|
        # if rejected, reward in empty
        item["select_reward"] = "" and break if item["answer_status"].to_i == 2 

        if rew["checked"]
          case rew["type"].to_i
          when 1
            item["select_reward"] = "#{rew["amount"].to_i}元话费"
          when 2
            item["select_reward"] = "#{rew["amount"].to_i}元支付宝"
          when 4 
            item["select_reward"] = "#{rew["amount"].to_i}积分"
          when 8
            lottery_link = "/lotteries/#{item["answer_id"]}"
            item["select_reward"] = %Q{<a class='lottery' target='_blank' href='#{lottery_link}'>抽奖机会</a>}
          when 16
            item["select_reward"] = "#{rew["amount"].to_i}集分宝"
          end

          break
        end
      end
      # return
      item 
    end

    @my_answer_surveys['data'] = data

    respond_to do |format|
      format.html { render 'join_surveys' } # adapt to alias index action
      format.json { render_json_auto @my_answer_surveys }
    end
  end

  alias :index :join_surveys

  #我推广的问卷
  # GET
  def spread_surveys

    @my_spread_surveys = auto_paginate current_user.survey_spreads.desc(:survey_creation_time) do |paginated_survey_spreads|
      paginated_survey_spreads.map do |e|
        finish_number = e.survey.answers.not_preview.finished.where(:introducer_id => current_user._id).length
        spread_number = e.survey.answers.not_preview.where(:introducer_id => current_user._id).length
        # e.survey.info_for_sample.merge({"spread_number" => e.times})
        e.survey.info_for_sample.merge({"spread_number" => spread_number,
                                        "finish_number" => finish_number})
      end
    end

    # @my_spread_surveys = @uclient.my_spread_surveys(page, per_page)

    respond_to do |format|
      format.html 
      format.json { render_json_auto @my_spread_surveys }
    end
  end

  # GET
  def survey_detail

    @survey = Survey.find_by_id(params[:id])
    render_404 and return if @survey.nil?
    @answers = @survey.answers.not_preview.where(:introducer_id => current_user._id.to_s).desc(:status)
    params[:per_page] = 9
    @answers = auto_paginate @answers do |paginate_answers|
      paginate_answers.map { |e| e.info_for_spread_details }
    end
    # @answers = @uclient.survey_spread_answers(params[:id], page, 9)

    respond_to do |format|
      format.html {
        render :layout => false if request.headers["OJAX"]
      }
      format.json { render_json_auto @answers }
    end
  end

  # GET
  def spread_counter
    @survey = Survey.find_by_id(params[:id])
    render_json_e ErrorEnum::SURVEY_NOT_EXIST and return if @survey.nil?
    @answers = @survey.answers.not_preview.where(:introducer_id => current_user._id.to_s)
    @total_answer_number = @answers.length
    @finished_answer_number = @answers.finished.length
    @editting_answer_number = @answers.where(:status => Answer::EDIT).length
    @spreaded_answer_number = {"total_answer_number" => @total_answer_number,
      "finished_answer_number" => @finished_answer_number,
      "editting_answer_number" => @editting_answer_number}
    # render_json_auto @spreaded_answer_number and return

    # @counter = @uclient.spread_answers_number(params[:id])

    respond_to do |format|
      format.json { render_json_auto @spreaded_answer_number }
    end
  end

  # *************** points ****************
  
  #积分记录
  # GET
  # params[:scope] = :all | :in | :out
  def points
    if params[:scope] == 'in'
      @logs = PointLog.where(:user_id => current_user.id, :amount.gt => 0)
    elsif params[:scope] == 'out' 
      @logs = PointLog.where(:user_id => current_user.id, :amount.lt => 0)
    else
      @logs = PointLog.where(:user_id => current_user.id)
    end
    @point_logs = auto_paginate @logs.desc(:created_at) do |paginated_logs|
      paginated_logs.map { |e| e.info_for_sample }
    end

    # @point_logs = @uclient.get_my_point_history(params[:scope], page, per_page)

    respond_to do |format|
      format.html 
      format.json { render_json_auto @point_logs and return }
    end
  end

  # **************** orders ***************

  # 我的礼品
  # ** scope: answer/lottery/point
  # 
  def orders
    scope = [1,2,4].include?(params[:scope].to_i) ? params[:scope].to_i : 1
    @orders = current_user.orders.where(:source => scope).desc(:created_at)
    @orders = auto_paginate(@orders) do |paginated_orders|
      paginated_orders.map { |e| e.info_for_sample }
    end

    # scope = [1,2,4].include?(params[:scope].to_i) ? params[:scope].to_i : 1
    # @orders = @uclient.get_my_orders(scope, page, per_page)

    respond_to do |format|
      format.html 
      format.json { render_json_auto @orders and return }
    end
  end
  #

  #订单详情查询
  def order_detail

    @order = Order.find_by_id(params[:id])
    render_404 and return if @order.nil?
    @order = @order.info_for_sample_detail


    # @order = @uclient.order_show(params[:id])

    respond_to do |format|
      format.html {
        render :layout => false if request.headers["OJAX"]
      }
      format.json { render_json_auto @order, :only => [:success] and return }
    end
  end

  # ************** setting *****************

  # def setting
  # end

  #个人资料
  # GET
  def basic_info
    @user_info = current_user.get_basic_attributes
    # @user_info = @uclient.basic_attrs

    respond_to do |format|
      format.html {
        @user_info["income_person"][1] = 99999999 if @user_info["income_person"].is_a?(Array) and @user_info["income_person"][1] == 1.0/0.0
        @user_info["income_family"][1] = 99999999 if @user_info["income_family"].is_a?(Array) and @user_info["income_family"][1] == 1.0/0.0
        @user_info["seniority"][1] = 99999999 if @user_info["seniority"].is_a?(Array) and @user_info["seniority"][1] == 1.0/0.0
        @user_info["income_person"][0] = -99999999 if @user_info["income_person"].is_a?(Array) and @user_info["income_person"][0] == -1.0/0.0
        @user_info["income_family"][0] = -99999999 if @user_info["income_family"].is_a?(Array) and @user_info["income_family"][0] == -1.0/0.0
        @user_info["seniority"][0] = -99999999 if @user_info["seniority"].is_a?(Array) and @user_info["seniority"][0] == -1.0/0.0
      }
      format.json { render_json_auto @user_info }
    end
  end

   #更改基本信息
   # PUT
  def update_basic_info
    # logger.error ".........\n#{params[:attrs].inspect}"
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
    # render_json_auto(retval) and return

    # @retval = @uclient.update_attrs(param_attrs)

    respond_to do |format|
      format.html {
        redirect_to :action => :basic_info
      }
      format.json { render_json_auto @retval }
    end
  end

  # GET 头像信息
  # return avatar link and email
  def avatar

  end

  #更新头像信息
  # POST
  def update_avatar
    @update_retval = false
    if @current_user_info
      avatar = Avatar.new 
      avatar.uid = @current_user_info['sample_id']
      unless params[:crop].empty?
        geo_arr = params[:crop].split(',').reverse
        avatar.crop_w = geo_arr[0]
        avatar.crop_h = geo_arr[1]
        avatar.crop_x = geo_arr[2]
        avatar.crop_y = geo_arr[3]
      end
      avatar.image = params[:avatar]
      avatar.store_image!
      @update_retval = true
    end
    render action: 'avatar'
  end

  #账户绑定
  # GET /users/setting/bindings
  def bindings

    @bindings = {}
    if current_user.email_activation
      @bindings["email"] = [current_user.email, current_user.email_subscribe]
    end
    if current_user.mobile_activation
      @bindings["mobile"] = [current_user.mobile, current_user.mobile_subscribe]
    end
    ["sina", "renren", "qq", "google", "kaixin001", "douban", "baidu", "sohu", "qihu360"].each do |website|
      third_party_user = ThirdPartyUser.where(:user_id => current_user._id.to_s, :website => website).first
      @bindings[website] = [third_party_user.name, third_party_user.share] if !third_party_user.nil?
    end

    # @bindings = @uclient.bindings

    respond_to do |format|
      format.html { }
      format.json { render_json_auto @bindings }
    end
  end

  #取消绑定具体账户
  # PUT /users/setting/unbind/:website
  def unbind
    third_party_user = ThirdPartyUser.where(:website => params[:website], :user_id => current_user._id.to_s).first
    third_party_user.destroy if !third_party_user.nil?
    render_json_s and return
=begin
    @retval = @uclient.unbind(params[:website])

    respond_to do |format|
      format.html {
        render :text => "error!", action: 'bindings' and return unless @retval.success
      }
      format.json { render_json_auto @retval }
    end
=end
  end

  # 绑定分享
  # PUT /users/setting/share?website=&share=
  def bind_share
    third_party_user = ThirdPartyUser.where(:website => params[:website], :user_id => current_user._id.to_s).first
    render_json_e ErrorEnum::THIRD_PARTY_USER_NOT_EXIST and return if third_party_user.nil?
    third_party_user.share = params[:share] == "true"
    third_party_user.save
    render_json_s and return
=begin
    @retval = @uclient.set_share(params[:website], params[:share])

    respond_to do |format|
      format.html {
        render :text => "error!", action: 'bindings' and return unless @retval.success
      }
      format.json { render_json_auto @retval }
    end
=end
  end

  # 绑定订阅
  # PUT /users/setting/subscribe?type=&sub=
  def bind_subscribe
    if params[:type] == "email"
      current_user.email_subscribe = params[:sub].to_s == "true" if current_user.email_activation
    else
      current_user.mobile_subscribe = params[:sub].to_s == "true" if current_user.mobile_activation
    end
    render_json_auto current_user.save and return

=begin
    @retval = @uclient.set_subscribe(params[:type], params[:sub])

    respond_to do |format|
      format.html { }
      format.json { render_json_auto @retval }
    end
=end
  end

  # 根据手机号发送验证短信
  # PUT /users/setting/change_mobile?m=
  def change_mobile
    render_json_e ErrorEnum::EMAIL_OR_MOBILE_EXIST and return if User.find_by_mobile(params[:m]).present?
    current_user.mobile_to_be_changed = params[:m]
    # current_user.sms_verification_code = Random.rand(100000..999999).to_s
    code = Tool.generate_active_mobile_code
    current_user.sms_verification_code = code
    current_user.sms_verification_expiration_time = Time.now.to_i + 2.hours.to_i
    tmp = current_user.save
    SmsWorker.perform_async("change_mobile", params[:m], "", :code => code)
    render_json_s and return

    # @retval = @uclient.change_mobile(params[:m])

    # render_json_auto @retval 
  end

  # 根据手机号和验证短信码激活手机
  # PUT /users/setting/check_mobile_verify_code?m=&code=
  def check_mobile_verify_code
    render_json_e ErrorEnum::MOBILE_NOT_EXIST and return if current_user.mobile_to_be_changed != params[:m]
    render_json_e ErrorEnum::ILLEGAL_ACTIVATE_KEY and return if current_user.sms_verification_code != params[:code]
    render_json_e ErrorEnum::ACTIVATE_EXPIRED if current_user.sms_verification_expiration_time < Time.now.to_i
    current_user.mobile = current_user.mobile_to_be_changed
    current_user.mobile_activation = true
    render_json_auto current_user.save and return

    # @retval = @uclient.check_mobile_verify_code(params[:m], params[:code])
    # render_json_auto @retval 
  end

  # 根据邮箱绑定
  # PUT /users/setting/change_mobile?email=
  def change_email
    render_json_e ErrorEnum::EMAIL_OR_MOBILE_EXIST and return if !User.find_by_email(params[:email]).nil?
    current_user ||= User.find_by_mobile(params[:mobile])
    render_json_e ErrorEnum::USER_NOT_EXIST and return unless current_user.present? 
    current_user.email_to_be_changed = params[:email]
    current_user.change_email_expiration_time = Time.now.to_i + OOPSDATA[RailsEnv.get_rails_env]["activate_expiration_time"].to_i
    current_user.save
    EmailWorker.perform_async("change_email",
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
=begin
    retval = User.activate("email", activate_info, request.remote_ip, params[:_client_type])  
    if retval.class == String && retval.start_with?("error_")
      @success = false
    else
      @success = true
      refresh_session(retval['auth_key'])
      user = User.find_by_auth_key(retval['auth_key'])
      @email  = Base64.encode64(user.email).chomp()
    end
=end
  end

  #收获地址
  # GET
  def address
    @receiver_info = current_user.affiliated.try(:receiver_info) || {}

    respond_to do |format|
      format.html { }
      format.json { render_json_auto @receiver_info }
    end
  end

  # PUT
  def update_logistic_address
    @retval = current_user.set_receiver_info(params[:receiver_info])

    # @retval = @uclient.update_logistic_address(params[:receiver_info])

    respond_to do |format|
      format.html { }
      format.json { render_json_auto @retval }
    end
  end

  # 密码
  # GET
  def password 

  end

  # PUT
  def update_password
    @retval = current_user.reset_password(params[:old_password], params[:new_password])

    respond_to do |format|
      format.html { }
      format.json { render_json_auto(@retval) and return }
    end
  end

  # ************* notifications ******************    

  def notifications
    @messages = current_user.messages
    @notices = auto_paginate @messages do |paginated_messages|
      paginated_messages.map { |e| e.info_for_sample }
    end

    @current_user.last_read_messeges_time = Time.now
    @current_user.save

    respond_to do |format|
      format.html 
      format.json { render_json_auto @notices }
    end
  end

  # DELETE
  # Delete notice from id
  def destroy_notification
    @message = Message.find_by_id(params[:id])
    render_json_e ErrorEnum::MESSAGE_NOT_EXIST and return if !current_user.messages.include?(@message)

    # @retval = @uclient.del_notice(params[:id])

    respond_to do |format|
      format.html { }
      format.json { render_json_auto @message.destroy }
    end
  end

  # DELETE
  # Delete All notifications
  def remove_notifications
    @retval = current_user.messages.destroy_all
    # @retval = @uclient.del_all_notices

    respond_to do |format|
      format.html { }
      format.json { render_json_auto @retval and return }
    end
  end

  # *******************************
  # =============================================
  # *******************************************

  private 
  
  def get_client
    @uclient = Sample::UserClient.new(session_info) 
  end

  def get_self_extend_info
    # current_user  = @uclient.get_basic_info.value


    # answer number, spread number, third party accounts
    @answer_number = current_user.answers.not_preview.finished.length
    @spread_number = Answer.where(:introducer_id => current_user._id).not_preview.finished.length
    @bind_info = {}
    ["sina", "renren", "qq", "google", "kaixin001", "douban", "baidu", "sohu", "qihu360"].each do |website|
      @bind_info[website] = !ThirdPartyUser.where(:user_id => current_user._id.to_s, :website => website).blank?
    end
    @bind_info["email"] = current_user.email_activation
    @bind_info["mobile"] = current_user.mobile_activation

    @completed_info = current_user.completed_info
    
    @current_user_info = {
      "answer_number" => @answer_number,
      "spread_number" => @spread_number,
      "bind_info" => @bind_info,
      "completed_info" => @completed_info,
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

  def point_nav
    @current_nav = 'points' 
  end

  def order_nav
    @current_nav = 'orders' 
  end

  def job_nav
    @current_nav = 'jobs'
  end

  def notification_nav
    @current_nav = 'notifications'
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