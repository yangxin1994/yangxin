# encoding: utf-8
class Sample::AccountsController < Sample::SampleController
  layout 'sample_account'

	before_filter :require_sign_in, :only => [:after_sign_in, :get_basic_info_by_auth_key]

  def sign_in

  end

  # FOR AJAX 
  def login
    result = User.login_with_email_mobile(params[:email_mobile],
                                          params[:password], 
                                          @remote_ip, 
                                          params[:_client_type], 
                                          params[:permanent_signed_in], 
                                          params[:third_party_user_id])
    refresh_session(result['auth_key'])
    render_json_auto result and return
  end
  
  # PAGE
  def after_sign_in
  	if cookies[Rails.application.config.bind_answer_id_cookie_key].blank?
  		redirect_to (params[:ref].blank? ? root_path : params[:ref])
  	else
  		# go to bind answer id to the current user
	  	redirect_to bind_sample_path({ref: params[:ref]})
  	end
  end
 
  def sign_up

  end

  def sign_out
  	_sign_out params[:ref]
  end

  #注册成功后的跳转页面
  def active_notice
    # mail.cn.yahoo.com
    #'gmail.com' 
    mails = ['126.com','163.com','sina.com','yahoo','qq.com']
    @account = params[:k]
    @account = Base64.decode64(@account)
  
    m = mails.select{|mail| @account.include?(mail)}
    if m.present?
      @mail_t = "http://www.mail.#{m.first}"
    end
  end

  def check_email_mobile
    u = User.find_by_email_mobile(params[:phone])
    render_json_auto({"exist" => (u &&  u.is_activated)}) and return
    # render :json => Sample::AccountClient.new(session_info).check_email_mobile(params[:phone])
  end

  #用户注册
  def create_sample
    if params[:phone].present?
      retval = User.create_new_user(
        params[:phone],
        params[:password],
        current_user,
        params[:third_party_user_id],
        "#{request.protocol}#{request.host_with_port}/account/email_activate")
      render_json_auto(retval) and return
    end
  end

  def re_mail
    @account = params[:k]
    @account = Base64.decode64(@account)

    user = nil
    if @account.match(User::EmailRexg)  ## match email
      user = User.find_by_email(@account.downcase)
    elsif @account.match(/^\d{11}$/)  ## match mobile
      user = User.find_by_mobile(@account)
    end
    render_json_e(ErrorEnum::USER_NOT_EXIST) and return if user.nil?
    render_json_e(ErrorEnum::USER_NOT_REGISTERED) and return if user.status == 0
    render_json_e(ErrorEnum::USER_ACTIVATED) and return if user.is_activated
    if @account.match(/^\d{11}$/)
      active_code = Tool.generate_active_mobile_code
      user.sms_verification_code = active_code
      user.sms_verification_expiration_time  = (Time.now + 2.hours).to_i
      user.save
      SmsWorker.perform_async("activate", user.mobile, "", :active_code => active_code)
    else
      EmailWorker.perform_async("welcome", user.email, "#{request.protocol}#{request.host_with_port}/account/email_activate")
    end
    render_json_s and return
  end

  #用户注册  邮件激活
  def email_activate
    activate_info = {}
    begin
      activate_info_json = Encryption.decrypt_activate_key(params[:key])
      activate_info = JSON.parse(activate_info_json)
    rescue
      @success = false and return
    end

    retval = User.activate("email", activate_info, @remote_ip, params[:_client_type])  
    if retval.class == String && retval.start_with?("error_")
      @success = false
    else
      @success = true
      refresh_session(retval['auth_key'])
      user = User.find_by_auth_key(retval['auth_key'])
      @email  = Base64.encode64(user.email).chomp()
    end


  end

  def mobile_activate
    activate_info = {"mobile" => params[:mobile],
        "password" => params[:password],
        "verification_code" => params[:verification_code]}
    retval = User.activate("mobile", activate_info, @remote_ip, params[:_client_type])

    render_json_e retval and return if retval.class == String && retval.start_with?("error_")
    refresh_session(retval['auth_key'])
    render_json_auto retval
  end

  def get_basic_info_by_auth_key
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
    
    @basic_info = {
      "answer_number" => @answer_number,
      "spread_number" => @spread_number,
      "bind_info" => @bind_info,
      "completed_info" => @completed_info,
      "point" => current_user.point,
      "sample_id" => current_user._id.to_s,
      "avatar" => current_user.mini_avatar,
      "nickname" => current_user.nickname
    }
    render_json_auto @basic_info and return
  end

  def forget_password
    mobilerexg = User::MobileRexg
    emailrexg  = User::EmailRexg
    @acc = Base64.decode64(params[:k]) if params[:k]
    @acc = Base64.decode64(params[:key])  if params[:key]
    @code = Base64.decode64(params[:c]) if params[:c]
    @completed = Base64.decode64(params[:acc]) if params[:acc]
    if((@acc.present? && @code.present?) || params[:key].present? )
      @step = 'third'
    elsif params[:k].present? && (@acc.match(/#{mobilerexg}/i) || @acc.match(/#{emailrexg}/i) )
      @step = 'second'
    elsif @completed.present? && (@completed.match(/#{mobilerexg}/i) || @completed.match(/#{emailrexg}/i) )
      @step = 'fourth'
    else
      @step = 'first'
    end
  end

  #根据激活邮箱的key找回忘记密码的账户
  def get_account
    begin
      activate_info_json = Encryption.decrypt_activate_key(params[:key])
      activate_info = JSON.parse(activate_info_json)
      user = User.find_by_email(activate_info['email'])
      render_404 if user.nil?
      redirect_to forget_password_account_path(:key => Base64.encode64(user.email).chomp())
    rescue
      return
    end
  end

  def send_forget_pass_code
    session[:forget_account] = params[:email_mobile]
    render_json_auto User.send_forget_pass_code(params[:email_mobile], 
      "#{request.protocol}#{request.host_with_port}/account/get_account") and return
  end

  def make_forget_pass_activate
    render_json_auto User.make_forget_pass_activate(params[:phone], params[:code]) and return
  end

  def generate_new_password
    render_json_auto User.generate_new_password(params[:email_mobile],params[:password])
  end
end