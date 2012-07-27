# encoding: utf-8
require 'error_enum'
class MessagesController < ApplicationController

	before_filter :require_sign_in
	before_filter :require_admin, :except => [:get_number_unlooked, :index]
 
	#*method*: get
	#
	#*url": /messages/:user_id
	#
	#*desciption*: if the parameter is nil and the user is administrator then  get all messages, if the parameter is not nil then get the receiver messages of the user
	#
	#*params*:
	#* id of the user
	#
	#*retval*:
	#* the message array objects
	#* USER_NOT_EXIST
	# 
	def index
		user_id = params[:user_id]
		if user_id.nil?
			require_admin
			@messages = Massege.all
		else  
			@messages = Message.get_messages(user_id)
			case @messages
				when ErrorEnum::USER_NOT_EXISTS
					flash[:notice] = "这个用户不存在"
					respond_to do |format|
						format.json { render :json => ErrorEnum::USER_NOT_EXISTS and return }
					end
			end
		end
		respond_to do |format|
			format.json { render json => @messages }
		end
	end
	
	#*method*: get
	#
	#*url": /messages/:message_id
	#
	#*desciption*: get message object
	#
	#*params*:
	#* user_id: id of the user doing this operation
	#* message_id: id of the message to be obtained
	#
	#*retval*:
	#* the message object
	#* MESSAGE_NOT_EXIST when the message is destroied
	#* AUTHROZIED when the user is not administrator   
	def show
		@user = User.find_by_id(params[:user_id])
		if @user.nil?
			flash[:notice] = "该用户不存在"
				respond_to do |format|
				format.json { render json => ErrorEnum:: USER_NOT_EXIST and return }
			end
		elseif @user.is_admin == false
			flash[:notice] = "该用户不是管理员，无权查看消息"
				respond_to do |format|
				format.json { render json => ErrorEnum::AUTHROZIED and return }
			end
		end	
		@message = Message.find_by_id(params[:message_id])
		case @message
			when ErrorEnum::MESSAGE_NOT_EXIST
				flash[:notice] = "这条消息不存在"
					respond_to do |format|
					format.json { render json => ErrorEnum:: MESSAGE_NOT_EXIST and return }
				end
			else
				respond_to do |format|
					format.json { render json => @message }
			end
		end
	end

	#*method*: post
	#
	#*url": /messages
	#
	#*desciption*: create a new message
	#
	#*params*: 
	#* title of the message
	#* content of the message
	#* id of the current user
	#* type of the message
	#* id of the receivers doing this operation
	#
	#*retval*:
	#* the new message instance: when successfully created
	#* THERE_ARE_SOME_RECEIVERS_NOT_EXIST : when there are some receivers not exist
	#* UNAUTHROZIED: when the sender is not administrator
	#* RECEIVER_CAN_NOT_BLANK: when receiver not exsit
	#* TITLE_CAN_NOT_BLANK: when the title of the message is blank
	#* CONTENT_CAN_NOT_BLANK: when the content of the message is blank
	def create
		@message = Message.check_and_create_new(params[:content],params[:title], params[:sender_id],params[:type], params[:receiver_ids])
		case @message
			when ErrorEnum::CONTENT_CAN_NOT_BLANK
				flash[:notice] = "内容不能为空"
				respond_to do |format|
					format.json	{ render :json => ErrorEnum::CONTENT_NOT_BLANK and return }
				end
			when ErrorEnum::TITLE_CAN_NOT_BLANK 
				flash[:notice] = "标题不能为空"
				respond_to do |format|
					format.json { render :json => ErrorEnum::TITLE_CAN_NOT_BLANK and return }
				end
			when ErrorEnum::RECEIVER_CAN_NOT_BLANK
				flash[:notice] = "发送给特定用户的消息，接收者不能为空"
				respond_to do |format|
					format.json { render :json => ErrorEnum::RECEIVER_CAN_NOT_BLANK and return }
				end
			when ErrorEnum::THERE_ARE_SOME_RECEIVERS_NOT_EXIST
				flash[:norice] = "有些指定的接收用户不存在"
				respond_to do |format|
					format.json { render :json => ErrorEnum::THERE_ARE_SOME_RECEIVERS_NOT_EXIST and return }
				end
			else
				@current_user.messages << @message
				flash[:notice] = "消息已成功创建"
				respond_to do |format|
				format.json { render :json => @message and return }
				end
		end 
	end

	#*method*: put
	#
	#*url": /messages/:message_id
	#
	#*desciption*: update a message
	#
	#*params*:
	#* message_id: id of the message to be updated
	#* message: the message object to be updated
	#
	#*retval*:
	#* the message object : when update the message successfully
	#* MESSAGE_NOT_EXIST : when the message not exists
	#* REQUIRE_ADMIN : when the user is not administrator
	def update
		@message = Message.find_by_id(params[:message_id])
		if @message.nil?
			flash[:notice] = "该消息不存在"
			respond_to do |format|
				format.json { render :json => ErrorEnum::MESSAGE_NOT_EXIST and return }
			end
				else
			retval = @message.update_message(params[:message])
			case retval
				when true
					flash[:notice] = "更新消息成功"
					respond_to do |format|
						format.json { render :json => @message }
					end
				else 
					respond_to do |format|
						format.json	{ render :json => "unknown error" and return }
					end
				end
		end
	end

	#*method*: delete
	#
	#*url": /messages/:message_id
	#
	#*desciption*: remove a message
	#
	#*params*:
	#* message_id: id of the message to be deleted
	#
	#*retval*:
	#* true : if the message is deleted
	#* MESSAGE_NOT_EXIST : when the message not exists
	#* REQUIRE ADMIN : when the user is not administrator
	def destroy
		@message = Message.find_by_id(params[:message_id])
		if @message.nil?
			flash[:notice] = "该消息不存在"
			respond_to do |format|
				format.json { render :json => ErrorEnum::MESSAGE_NOT_EXIST and return }
			end
		else
			if @message.destroy()
				flash[:notice] = "删除成功"
				respond_to do |format|
					format.json { render :json => true and return }
				end
			else 
				flash[:notice] = "删除失败"
				respond_to do |format|
					format.json { render :json => false and return }
				end
			end
		end
	end

	#*method*: get_number_unlooked
	#
	#*url": /messages/:user_id
	#
	#*desciption*: get the number of user's messages which the user hasn't looked
	#
	#*params*:
	#* id of the user doing this operation
				#* the last time of user looking messages 
	#
	#*retval*:
	#* the number of user's unlooked messages
				#* USER_NOT_EXIST :when the user not exists
	def get_number_unlooked
		user_id = params[:user_id]
		last_visit_time = params[:last_visit_time]
		number = Message.get_number_unlooked(user_id, last_visit_time)
		case number
			when ErrorEnum::USER_NOT_EXIST
				flash[:norice] = "这个用户不存在"
				respond_to do |format|
					format.json { render :json => ErrorEnum::USER_NOT_EXISTS and return }
				end
			else
				respond_to do |format|
					format.json { render :json => number and return }
				end
		end
	end                
end
