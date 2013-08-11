# encoding: utf-8
require 'error_enum'
class Sample::UsersController < ApplicationController

	#############################
	#功能:用户点击“立即参与”，获取最新的热点小调查
	#http method：get
	#传入参数: 无
	#返回的参数:一个盛放排行榜用户的列表
	#############################		
	def get_top_ranks
		@users = User.sample.where(:is_block => false).desc(:point).limit(5)
		@users = @users.map{|user| user['nickname'] = user.nickname;user['spread_count'] = user.spread_count;user['answer_count'] = user.answers.not_preview.count;user['avatar_src']= user.avatar? ? user.avatar.picture_url : User::DEFAULT_IMG;user}
		render_json { @users }
	end

	def get_my_third_party_user
		users = @current_user.third_party_users
		render_json_auto(users)
	end

	def mobile_banding
		render_json_auto(@current_user.mobile_activation)
	end

	def email_banding
		render_json_auto(@current_user.email_activation)    
	end

	def info_precent_complete
		render_json_auto(@current_user.completed_info) 
	end

	#生成订阅用户并发激活码或者邮件
	def make_rss_activate
		retval = User.create_rss_user(params[:rss_channel],params[:callback])
		render_json_auto retval
	end 

	#订阅邮件激活
	def make_subscribe_active  
		begin
			activate_info_json = Encryption.decrypt_activate_key(params[:key])
			activate_info = JSON.parse(activate_info_json)
		rescue
			render_json_e(ErrorEnum::ILLEGAL_ACTIVATE_KEY) and return
		end

		retval = User.activate_rss_subscribe(activate_info)
		render_json_auto(retval) and return    
	end

	#取消订阅
	def cancel_subscribe
		begin
			activate_info_json = Encryption.decrypt_activate_key(params[:key])
			activate_info = JSON.parse(activate_info_json)
		rescue
			render_json_e(ErrorEnum::ILLEGAL_ACTIVATE_KEY) and return
		end	
		retval = User.cancel_subscribe(activate_info)
		render_json_auto(retval) and return   			
	end


	# def send_activate_key
	#   user = nil
	#   if params[:email_mobile].match(/\w+([-+.]\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*/)  ## match email
	#     user = User.find_by_email(params[:email_mobile].downcase)
	#   elsif params[:email_mobile].match(/^\d{11}$/)  ## match mobile
	#     user = User.find_by_mobile(params[:email_mobile])
	#   end
	#   render_json_e(ErrorEnum::USER_NOT_EXIST) and return if user.nil?
	#   render_json_e(ErrorEnum::USER_NOT_REGISTERED) and return if user.status == 0
	#   render_json_e(ErrorEnum::USER_ACTIVATED) and return if user.is_activated
	#   if params[:email_mobile].match(/^\d{11}$/)
	#     ##TODO send_mobile_message()
	#   else
	#     #EmailWorker.perform_async("activate", user.email, params[:callback])
	#     EmailWorker.perform_async("welcome", user.email, params[:callback])
	#   end
	#   render_json_s and return
	# end



	def make_rss_mobile_activate
		mobile = params[:email_mobile]
		code   = params[:code]
		user   = User.find_by_mobile("#{mobile}")
		return USER_NOT_EXIST  if !user.present?
		retval = user.make_mobile_rss_activate(code)           
		render_json_auto(retval)
	end

	def send_forget_pass_code
		email_mobile = params[:email_mobile]
		callback  = params[:callback]
		render_json_auto User.send_forget_pass_code(email_mobile,callback)
	end

	def make_forget_pass_activate
		mobile = params[:mobile]
		code   = params[:code]
		render_json_auto User.make_forget_pass_activate(mobile,code)
	end

	def generate_new_password
		render_json_auto User.generate_new_password(params[:email_mobile],params[:password])
	end

	def get_account_by_activate_key
		begin
			activate_info_json = Encryption.decrypt_activate_key(params[:activate_key])
			activate_info = JSON.parse(activate_info_json)
			render_json_auto User.get_account_by_activate_key(activate_info)
		rescue
			render_json_e(ErrorEnum::ILLEGAL_ACTIVATE_KEY) and return
		end
	end

end