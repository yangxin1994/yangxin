class ApplicationController < ActionController::Base
	protect_from_forgery

	before_filter :client_ip, :current_user, :update_last_visit_time, :user_init

	helper_method :user_signed_in?, :user_signed_out?
###################################################
	# QuillMe
	def self.def_each(*method_names, &block)
		method_names.each do |method_name|
			define_method method_name do
				instance_exec method_name, &block
			end
		end
	end

	begin "kaminari"
		def page
			params[:page] || 1
		end

		def per_page
			params[:per_page] || 25
		end
	end

	def render_404
		render_optional_error_file(404)
	end

	def render_403
		render_optional_error_file(403)
	end

	def render_optional_error_file(status_code)
		status = status_code.to_s
		if ["404","403", "422", "500"].include?(status)
			render :template => "/errors/#{status}", :format => [:html], :handler => [:erb], :status => status, :layout => "application"
		else
			render :template => "/errors/unknown", :format => [:html], :handler => [:erb], :status => status, :layout => "application"
		end
	end

	def notice_success(msg)
		flash[:notice] = msg
	end

	def notice_error(msg)
		flash[:notice] = msg
	end

	def notice_warning(msg)
		flash[:notice] = msg
	end
	
################################################
	#get the information of the signed user and set @current_user
	def current_user
		current_user_id = get_cookie(:current_user_id)
		@current_user = current_user_id.nil? ? User.create_new_visitor_user : User.find_by_id(current_user_id)
	end

	def update_last_visit_time
		@current_user.update_last_visit_time if !@current_user.nil?
	end

	def user_init
		return if !user_signed_in?
		case @current_user.status
		when 3
			redirect_to fill_basic_info_path and return 
		when 4
			# Bug?
			#redirect_to import_friends_path and return 
		when 5
			redirect_to first_survey_path and return 
		end
	end

	#obtain the ip address of the clien, and set it as @remote_ip
	def client_ip
		#@remote_ip = request.env["HTTP_X_FORWARDED_FOR"]
		@remote_ip = request.remote_ip
	end

	#judge whether there is a user signed in currently
	def user_signed_in?
		#logger.info "#{@current_user}"
		return !!@current_user && get_cookie(:auth_key).to_s != "" && @current_user.auth_key == get_cookie(:auth_key)
	end

	#judge whether there is no user signed in currently
	def user_signed_out?
		!user_signed_in?
	end

	#judge whether the current user is admin
	def user_admin?
		user_signed_in? && @current_user.is_admin
	end

	
	def require_admin
		if !user_signed_in?
			respond_to do |format|
				format.html { redirect_to root_path and return }
				format.json	{ render :json => ErrorEnum::REQUIRE_LOGIN and return }
			end
		end
		if !user_admin?
			respond_to do |format|
				format.html { redirect_to root_path and return }
				format.json	{ render :json => ErrorEnum::REQUIRE_ADMIN and return }
			end
		end
	end

	#if no user signs in, redirect to root path
	def require_sign_in
		if !user_signed_in?
			respond_to do |format|
				format.html { redirect_to root_path and return }
				format.json	{ render :json => ErrorEnum::REQUIRE_LOGIN and return }
			end
		end
	end

	#if user signs in, redirect to home path
	def require_sign_out
		if !user_signed_out?
			respond_to do |format|
				format.html { redirect_to home_path and return }
				format.json	{ render :json => ErrorEnum::REQUIRE_LOGOUT and return }
			end
		end
	end

	#set cookie given a pair of key and value
	def set_cookie(key, value, expire_time = nil)
		cookies[key.to_sym] = expire_time.nil? ? value : {:value => value, :expires => expire_time}
	end

	#get cookie given a key
	def get_cookie(key)
		return cookies[key.to_sym]
	end

	def decrypt_third_party_user_id(string)
		begin
			h = JSON.parse(Encryption.decrypt_third_party_user_id(string))
			return [h["website"], h["user_id"]]
		rescue
			return nil
		end
	end 

	# method: in-accessible
	# description: help set session for an account
	def set_login_cookie(email_username, keep_signed_in)
		user = User.find_by_email_username(email_username)
		return false if user.nil?
		if keep_signed_in
			set_cookie(:current_user_id, user.id, 1.months.to_i) 
		else
			set_cookie(:current_user_id, user.id) 
		end
		auth_key = Encryption.encrypt_auth_key("#{user.id}&#{Time.now.to_i.to_s}")
		if keep_signed_in
			set_cookie(:auth_key, auth_key, keep_signed_in, 1.months.to_i)
		else
			set_cookie(:auth_key, auth_key, keep_signed_in)
		end
		return user.set_auth_key(user.id, auth_key)
	end

	def set_logout_cookie
		set_cookie(:current_user_id, nil) 
		set_cookie(:auth_key, nil) 
	end


	# page operate
	def slice(arr, page, per_page)
		return [] if !arr.instance_of?(Array)

		page ||= 1
		per_page ||= 10
		page = page.to_i
		per_page = per_page.to_i

		return [] if page < 1 || per_page < 1

		return arr.slice((page - 1)*per_page - 1, per_page)
	end
end
