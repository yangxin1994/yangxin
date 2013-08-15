# encoding: utf-8
class Sample::AccountsController < Sample::SampleController
  layout 'sample_account'

	before_filter :require_sign_in, :only => [:after_sign_in]

  def sign_in

  end

  # FOR AJAX 
  def login
    result = Sample::AccountClient.new(session_info).login(params[:email_mobile], params[:password], 
    params[:third_party_user_id], params[:permanent_signed_in])
    refresh_session(result.value['auth_key'])
  	render :json => result
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
    render :json => Sample::AccountClient.new(session_info).check_email_mobile(params[:phone])
  end

  #用户注册
  def create_sample
    if params[:phone].present?
      result = Sample::AccountClient.new(session_info).create_sample(params[:phone],params[:password],"#{request.protocol}#{request.host_with_port}/account/email_activate",params['third_party_user_id'])
      render :json => result            
    end
  end

  def re_mail
    @account = params[:k]
    @account = Base64.decode64(@account)
    render :json => Sample::AccountClient.new(session_info).re_mail(@account,"#{request.protocol}#{request.host_with_port}/account/email_activate")
  end

  #用户注册  邮件激活
  def email_activate
    result  =  Sample::AccountClient.new(session_info).email_activate(params[:key],'web')
    account =  Sample::UserClient.new(session_info).get_account(params[:key])

    @email  = Base64.encode64(account.value).chomp()
    if result.success
      @success = true
      refresh_session(result.value['auth_key'])
      #redirect_to after_sign_in_account_url
      #redirect_to home_path
    else
      @success = false
    end
    
  end

  def mobile_activate
    result =  Sample::AccountClient.new(session_info).mobile_activate(params[:mobile],params[:password],params[:verification_code])
    if result.success
      refresh_session(result.value['auth_key'])
    end
    render :json => result
  end

  def get_basic_info_by_auth_key
    render :json =>  Sample::UserClient.new(session_info).get_basic_info
  end

  def forget_password
    mobilerexg = '^(13[0-9]|15[0|1|2|3|6|7|8|9]|18[8|9])\d{8}$'
    emailrexg  = '\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z'
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
    result =  Sample::UserClient.new(session_info).get_account(params[:key])
    if result.success
      redirect_to forget_password_account_path(:key => Base64.encode64(result.value).chomp())
    end
  end

  def send_forget_pass_code
    session[:forget_account] = params[:email_mobile]
    result = Sample::UserClient.new(session_info).send_forget_pass_code(params[:email_mobile],"#{request.protocol}#{request.host_with_port}/account/get_account")
    render :json =>  result
  end

  def make_forget_pass_activate
    render :json =>  Sample::UserClient.new(session_info).make_forget_pass_activate(params[:phone],params[:code])
  end

  def generate_new_password
    render :json =>  Sample::UserClient.new(session_info).generate_new_password(params[:email_mobile],params[:password])
  end

end