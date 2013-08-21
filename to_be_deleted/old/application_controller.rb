class ApplicationController < ActionController::Base
	protect_from_forgery

	before_filter :client_ip, :current_user

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

	def auto_paginate(value, count = nil)
		retval = {}
		retval["current_page"] = page
		retval["per_page"] = per_page
		retval["previous_page"] = (page - 1 > 0 ? page-1 : 1)
		# retval["previous_page"] = [page - 1, 1].max

		# 当没有block或者传入的是一个mongoid集合对象时就自动分页
		# TODO : 更优的判断是否mongoid对象?
		# instance_of?(Mongoid::Criteria) .by lcm
		# if block_given? 
			if value.methods.include? :page
				count ||= value.count
				value = value.page(retval["current_page"]).per(retval["per_page"])
			elsif value.is_a?(Array) and value.count > per_page
				count ||= value.count
				value = value.slice((page-1)*per_page, per_page)
			end
			
	  		if block_given?
	  			retval["data"] = yield(value) 
	  		else
	  			retval["data"] = value
	  		end
		# else
		# 	#retval["data"] = eval(value + '.page(retval["current_page"]).per(retval["per_page"])' )
		# 	retval["data"] = value.page(retval["current_page"]).per(retval["per_page"])
		# end
		retval["total_page"] = ( (count || value.count )/ per_page.to_f ).ceil
		retval["total_page"] = retval["total_page"] == 0 ? 1 : retval["total_page"]
		retval["next_page"] = (page+1 <= retval["total_page"] ? page+1: retval["total_page"])
		# retval["next_page"] = [page + 1, retval["total_page"]].min
		retval
	end

	begin "kaminari"
		def page
			#params[:page].to_i == 0 ? 1 : params[:page].to_i - 1
			params[:page].to_i == 0 ? 1 : params[:page].to_i
		rescue
			1
		end

		def per_page
			params[:per_page].to_i == 0 ? 10 : params[:per_page].to_i
		rescue
			10
		end
	end

	def render_json(is_success = true, options = {}, &block)
		options[:only]+= [:value, :success] unless options[:only].nil?
		@is_success = is_success
		render :json => {:value => block_given? ? yield(@is_success) : @is_success ,
										 :success => @is_success
		}, :except => options[:except], :only => options[:only]		
	end

	def success_true
		@is_success = true
	end
	
################################################
	#get the information of the signed user and set @current_user
	def current_user
		@current_user = params[:auth_key].nil? ? nil : User.find_by_auth_key(params[:auth_key])
		return @current_user
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
		user_signed_in? && @current_user.is_admin?
	end

	#judge whether the current user is interviewer
	def user_interviewer?
		user_signed_in? && (@current_user.is_interviewer || @current_user.is_admin?)
	end

	#judge whether the current user is answer auditor
	def user_answer_auditor?
		user_signed_in? && (@current_user.is_answer_auditor? || @current_user.is_admin?)
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
	
	def require_answer_auditor
		render_json_e(ErrorEnum::REQUIRE_LOGIN) and return if !user_signed_in?
		render_json_e(ErrorEnum::REQUIRE_ANSWER_AUDITOR) and return if !user_answer_auditor?
	end
	
	def require_interviewer
		if !user_signed_in?
			respond_to do |format|
				format.html { redirect_to root_path and return }
				format.json	{ render_json_e(ErrorEnum::REQUIRE_LOGIN) and return }
			end
		end
		if !user_interviewer? && !user_admin?
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

		page = page.nil? || page.to_s.empty? ? 1 : page.to_i
		per_page = per_page.nil? || per_page.to_s.empty? ? 10 : per_page.to_i
		return [] if page < 1 || per_page < 1 

		### sort
		if arr.count > 1 && arr[0].respond_to?(:created_at) then
			arr.sort!{|v1, v2| v2.created_at <=> v1.created_at}
		end

		# avoid arr = nil
		arr = arr.slice((page-1)*per_page, per_page) || []
		return arr
	end

	# return error
	def return_json(is_success, value, options = {})
		options[:only] = options[:only].to_a + [:success, :value] if options[:only]
		render :json => {
				:success => is_success,
				:value => value
			},
			:except => options[:except], 
			:only => options[:only]
	end
	def render_json_e(error_code)
		error_code_obj = {
			:error_code => error_code,
			:error_message => ""
		}
		return_json(false, error_code_obj)
	end
	def render_json_s(value = true, options={})
		return_json(true, value, options)
	end
	def render_json_auto(value = true, options={})
		is_success = !((value.class == String && value.start_with?('error_')) || value.to_s.to_i < 0)
		is_success ? render_json_s(value, options) : render_json_e(value)
	end
end