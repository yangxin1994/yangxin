class ApplicationController < ActionController::Base
	protect_from_forgery

	before_filter :client_ip, :current_user, :user_init

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

	def respond_and_render(is_success = true, options = {}, &block)
		options[:only]+= [:value, :success] unless options[:only].nil?
		respond_to do |format|
			format.json do
				unless options[:format].nil?
				 	render options[:format], :except => options[:except],
				 													 :only => options[:only]
				end
				render :html
				render :json => {
								:value => yield,
								:success => is_success
							 },
							:except => options[:except], 
							:only => options[:only]
			end
		end		
	end
	def respond_and_render_json(is_success = true, options = {}, &block)
		options[:only]+= [:value, :success] unless options[:only].nil?
		respond_to do |format|
			format.json do
				render :json => {:value => yield,
												 :success => is_success
				 }, :except => options[:except], :only => options[:only]
			end
		end		
	end
	def respond_and_render_instance(instance)
		retval = instance.as_retval
		respond_to do |format|
			format.json do
				render :json => {
					:value => retval,
					:success => retval
				 }
			end
		end		
	end
################################################
	#get the information of the signed user and set @current_user
	def current_user
		if params[:auth_key] == nil
			@current_user = nil
		else
			@current_user = User.find_by_auth_key(params[:auth_key])
		end
		return @current_user
	end

	def user_init
		return if !user_signed_in?
		case @current_user.status
		when 2
			render_json_e(ErrorEnum::REQUIRE_INIT_STEP_1) and return 
		when 3
			render_json_e(ErrorEnum::REQUIRE_INIT_STEP_2) and return 
		end
	end

	#obtain the ip address of the clien, and set it as @remote_ip
	def client_ip
		#@remote_ip = request.env["HTTP_X_FORWARDED_FOR"]
		@remote_ip = params[:_remote_ip]
		@remote_ip = request.remote_ip if @remote_ip.blank?
	end

	#judge whether there is a user signed in currently
	def user_signed_in?
		return @current_user && @current_user.status >= 2
	end

	#judge whether there is no user signed in currently
	def user_signed_out?
		!user_signed_in?
	end

	#judge whether the current user is admin
	def user_admin?
		user_signed_in? && @current_user.is_admin
	end

	#judge whether the current user is survey auditor
	def user_survey_auditor?
		user_signed_in? && @current_user.is_survey_auditor
	end

	#judge whether the current user is entry clerk
	def user_entry_clerk?
		user_signed_in? && @current_user.is_entry_clerk
	end

	#judge whether the current user is answer auditor
	def user_interviewer?
		user_signed_in? && @current_user.is_interviewer
	end
	
	def require_admin
		if !user_signed_in?
			respond_to do |format|
				format.html { redirect_to root_path and return }
				format.json	{ render_json_e(ErrorEnum::REQUIRE_LOGIN) and return }
			end
		end
		if !user_admin?
			respond_to do |format|
				format.html { redirect_to root_path and return }
				format.json	{ render_json_e(ErrorEnum::REQUIRE_ADMIN) and return }
			end
		end
	end
	
	def require_survey_auditor
		if !user_signed_in?
			respond_to do |format|
				format.html { redirect_to root_path and return }
				format.json	{ render_json_e(ErrorEnum::REQUIRE_LOGIN) and return }
			end
		end
		if !user_survey_auditor?
			respond_to do |format|
				format.html { redirect_to root_path and return }
				format.json	{ render_json_e(ErrorEnum::REQUIRE_SURVEY_AUDITOR) and return }
			end
		end
	end
	
	def require_answer_auditor
		if !user_signed_in?
			respond_to do |format|
				format.html { redirect_to root_path and return }
				format.json	{ render_json_e(ErrorEnum::REQUIRE_LOGIN) and return }
			end
		end
		if !user_answer_auditor?
			respond_to do |format|
				format.html { redirect_to root_path and return }
				format.json	{ render_json_e(ErrorEnum::REQUIRE_ANSWER_AUDITOR) and return }
			end
		end
	end
	
	def require_entry_clerk
		if !user_signed_in?
			respond_to do |format|
				format.html { redirect_to root_path and return }
				format.json	{ render_json_e(ErrorEnum::REQUIRE_LOGIN) and return }
			end
		end
		if !user_entry_clerk?
			respond_to do |format|
				format.html { redirect_to root_path and return }
				format.json	{ render_json_e(ErrorEnum::REQUIRE_ENTRY_CLERK) and return }
			end
		end
	end
	
	def require_interviewer
		if !user_signed_in?
			respond_to do |format|
				format.html { redirect_to root_path and return }
				format.json	{ render_json_e(ErrorEnum::REQUIRE_LOGIN) and return }
			end
		end
		if !user_interviewer?
			respond_to do |format|
				format.html { redirect_to root_path and return }
				format.json	{ render_json_e(ErrorEnum::REQUIRE_INTERVIEWER) and return }
			end
		end
	end

	def require_user_exist
		if !@current_user
			respond_to do |format|
				format.html { redirect_to root_path and return }
				format.json	{ render_json_e(ErrorEnum::USER_NOT_EXIST) and return }
			end
		end
	end

	#if no user signs in, redirect to root path
	def require_sign_in
		if !user_signed_in?
			respond_to do |format|
				format.html { redirect_to root_path and return }
				format.json	{ render_json_e(ErrorEnum::REQUIRE_LOGIN) and return }
			end
		end
	end

	#if user signs in, redirect to home path
	def require_sign_out
		if !user_signed_out?
			respond_to do |format|
				format.html { redirect_to home_path and return }
				format.json	{ render_json_e(ErrorEnum::REQUIRE_LOGOUT) and return }
			end
		end
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

	# paging operate
	def slice(arr, page, per_page)
		arr = arr.to_a if arr.instance_of?(Mongoid::Criteria)
		return [] if !arr.instance_of?(Array)

		page = page.nil? ? 1 : page.to_i
		per_page = per_page.nil? ? 10 : per_page.to_i
		return [] if page < 1 || per_page < 1 

		### sort
		if arr.count > 1 && arr[0].respond_to?(:updated_at) then
			arr.sort!{|v1, v2| v2.updated_at <=> v1.updated_at}
		end

		# avoid arr = nil
		arr = arr.slice((page-1)*per_page, per_page) || []
		return arr
	end

	# return error
	def return_json(is_success, value)
		render :json => {
			:success => is_success,
			:value => value
		}
	end
	def render_json_e(error_code)
		error_code_obj = {
			:error_code => error_code,
			:error_message => ""
		}
		return_json(false, error_code_obj)
	end
	def render_json_s(value = true)
		return_json(true, value)
	end
	def render_json_auto(value = true)
		is_success = !(value.class == String && value.start_with?('error_'))
		is_success ? render_json_s(value) : render_json_e(value)
	end
end
