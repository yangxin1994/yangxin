class Sample::AccountsController < Sample::SampleController
  layout 'sample_account'

  before_filter :require_sign_in, :only => [:after_sign_in, :get_basic_info_by_auth_key]

  def sign_in
  end

  def sign_up
  end

  def sign_out
    _sign_out params[:ref]
  end

  # FOR AJAX
  def login
    result = User.login_with_email_mobile(
      email_mobile: params[:email_mobile],
      password: params[:password],
      client_ip: request.remote_ip,
      client_type: params[:_client_type],
      keep_signed_in: params[:permanent_signed_in],
      third_party_user_id: params[:third_party_user_id])

    refresh_session(result['auth_key'])
    render_json_auto result and return
  end

  # PAGE
  def after_sign_in
    if cookies[Rails.application.config.bind_answer_id_cookie_key].blank?
      redirect_to (params[:ref].blank? ? root_path : params[:ref])
    else
      redirect_to bind_sample_path({ref: params[:ref]})
    end
  end

  # 检查图片验证码是否正确
  def check_picture_code
    if session[:picture_code] == params[:code].to_s.upcase
      render_json_s
    else
      render_json_e 'error_captcha'
    end
  end

  #用户注册
  def regist
    if params[:email_mobile].present?
      retval = User.create_new_user(
        email_mobile: params[:email_mobile],
        password: params[:password],
        current_user: current_user,
        third_party_user_id: params[:third_party_user_id],
        callback:{
          protocol_hostname: "#{request.protocol}#{request.host_with_port}",
          path: "/account/email_activate"})
      render_json_auto(retval) and return
    end
  end

  def check_user_exist
    transfer_picture_code
    u = User.find_by_email_or_mobile(params[:email_mobile])
    render_json_auto({ exist: (u && u.is_activated)}) and return
  end

  def transfer_picture_code
    session[:picture_code] = session[:captcha].to_s.upcase
    if params[:code]
      render_json_s
    end
  end

  #注册成功后的跳转页面
  def regist_succ
    mails = %w(126.com 163.com sina.com yahoo qq.com)
    @account = params[:k]
    @account = Base64.decode64(@account)
    m = mails.select{ |mail| @account.include?(mail) }
    if m.present?
      @mail_t = "http://www.mail.#{m.first}"
    end
  end

  def re_mail
    @account = params[:k]
    @account = Base64.decode64(@account)

    user = nil
    if @account.match(User::EmailRexg)  ## match email
      user = User.find_by_email(@account.downcase) # raise error if not found
    elsif @account.match(/^\d{11}$/)  ## match mobile
      user = User.find_by_mobile(@account) #raise error if not found
    end

    render_json_e(ErrorEnum::USER_NOT_EXIST) and return if user.nil?
    render_json_e(ErrorEnum::USER_NOT_REGISTERED) and return if user.status == 0
    render_json_e(ErrorEnum::USER_ACTIVATED) and return if user.is_activated
    if @account.match(/^\d{11}$/)
      if user.sms_verification_code.present? && user.sms_verification_expiration_time > Time.now.to_i
        active_code = user.sms_verification_code
      else
        active_code = Tool.generate_active_mobile_code
        user.sms_verification_code = active_code
        user.sms_verification_expiration_time  = (Time.now + 2.hours).to_i
        user.save
      end
      SmsWorker.perform_async("activate", user.mobile, "", :active_code => active_code)
    else
      EmailWorker.perform_async(
        "welcome",
        user.email,
        "#{request.protocol}#{request.host_with_port}",
        "/account/email_activate")
    end
    render_json_s and return
  end

  #用户注册  邮件激活callback
  def email_activate
    activate_info = {}
    begin
      activate_info_json = Encryption.decrypt_activate_key(params[:key])
      activate_info = JSON.parse(activate_info_json)
    rescue
      @success = false and return
    end

    retval = User.activate("email", activate_info, request.remote_ip, params[:_client_type])
    if retval.class == String && retval.start_with?("error_")
      @success = false
    else
      @success = true
      #refresh_session(retval['auth_key'])
      user = User.find_by_auth_key(retval['auth_key'])
      @email  = Base64.encode64(user.email).chomp()
    end
  end

  #用户注册  手机验证码激活
  def mobile_activate
    activate_info = {
      "mobile" => params[:mobile],
      "password" => params[:password],
      "verification_code" => params[:verification_code]}

    retval = User.activate("mobile", activate_info, request.remote_ip, params[:_client_type])

    render_json_e retval and return if retval.class == String && retval.start_with?("error_")
    #refresh_session(retval['auth_key'])
    render_json_auto retval
  end

  def get_basic_info_by_auth_key
    @answer_number = current_user.answers.not_preview.finished.length
    @spread_number = Answer.my_spread(current_user._id).not_preview.finished.length

    @bind_info = {}
    %w(sina renren qq google kaixin001 douban baidu sohu qihu360).each do |website|
      @bind_info[website] = !ThirdPartyUser.where(:user_id => current_user._id.to_s, :website => website).blank?
    end

    @bind_info["email"] = current_user.email_activation
    @bind_info["mobile"] = current_user.mobile_activation

    @completed_info = current_user.completed_info
    @receiver_completed = current_user.receiver_completed_info

    @basic_info = {
      answer_number: @answer_number,
      spread_number: @spread_number,
      bind_info: @bind_info,
      completed_info: @completed_info,
      receiver_completed:@receiver_completed,
      point: current_user.point,
      sample_id: current_user._id.to_s,
      avatar: current_user.mini_avatar,
      nickname: current_user.nickname
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

  #根据激活邮箱的key找回忘记密码的账户callback
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

  # send email/mobile  code  when forget password
  def send_forget_pass_code
    session[:forget_account] = params[:email_mobile]
    retval = User.send_forget_pass_code(
      params[:email_mobile],
      {
        protocol_hostname: "#{request.protocol}#{request.host_with_port}",
        path: "/account/get_account"
      })

    render_json_auto retval and return
  end

  #忘记密码,手机激活
  def forget_pass_mobile_activate
    render_json_auto User.forget_pass_mobile_activate(params[:phone], params[:code]) and return
  end

  def generate_new_password
    render_json_auto User.generate_new_password(params[:email_mobile],params[:password])
  end
end
