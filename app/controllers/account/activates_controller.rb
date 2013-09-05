class Account::ActivatesController < ApplicationController
	# layout 'sign'

  before_filter :require_sign_out

	# PAGE
	def new
  	@signin_btn = true
  	
		render :template => 'account/activates/new_quill', :layout => 'sign'

	end

	# AJAX
	def create
		render :json => Account::RegistrationClient.new(session_info).send_activate_email(
			params[:email], "#{request.protocol}#{request.host_with_port}/activate")
	end

	# PAGE
	def done
  	@signin_btn = true
  	
  	@signup_email = params[:e]
  	if @signup_email.blank?
  		redirect_to root_path and return
  	end
  	@signup_email.downcase!
  	if !@signup_email.index('@gmail.').nil?
  		@mail_url = "http://gmail.com"
  	elsif !@signup_email.index('@tencent.').nil?
  		@mail_url = "http://mail.qq.com"
  	else
	  	@mail_url = "http://mail.#{@signup_email[(@signup_email.index('@') + 1)..(@signup_email.length)]}"
	  end

  	@is_register = params[:r].to_b

		render :template => 'account/activates/done_quill', :layout => 'sign'
	end

	# PAGE. Check the activate key
	def show
  	@signin_btn = true
  	
		@success = false
		key = params[:key]
		return if key.blank?
		result = Account::RegistrationClient.new(session_info).activate(key)
		@success = result.success
		if result.success
			refresh_session(result.value['auth_key'])
		end

		render :template => 'account/activates/show_quill', :layout => 'sign'
	end

end
