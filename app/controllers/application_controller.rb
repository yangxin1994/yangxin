class ApplicationController < ActionController::Base
  protect_from_forgery

	before_filter :client_ip, :current_user

	helper_method :user_signed_in?, :user_signed_out?

	#get the information of the signed user and set @current_user
	def current_user
		current_user_email = get_session(:current_user_email)
		if User.get_auth_key(current_user_email) == get_session(:auth_key)
			@current_user = User.find_by_email(current_user_email)
		else
			@current_user = nil
		end
	end

	#obtain the ip address of the clien, and set it as @remote_ip
	def client_ip
		@remote_ip = request.env["HTTP_X_FORWARDED_FOR"]
	end

	#judge whether there is a user signed in currently
	def user_signed_in?
		!!@current_user
	end

	#judge whether there is no user signed in currently
	def user_signed_out?
		!user_signed_in?
	end

	#if no user signs in, redirect to root path
	def require_sign_in
		if !user_signed_in?
			redirect_to root_path and return
		end
	end

	#if user signs in, redirect to home path
	def require_sign_out
		if !user_signed_out?
			redirect_to home_path and return
		end
	end

	#set session given a pair of key and value
	def set_session(key, value, expire = nil)
		session[key] = value
	end

	#get session given a key
	def get_session(key)
		return session[key]
	end

end
