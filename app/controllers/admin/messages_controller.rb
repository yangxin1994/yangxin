class Admin::MessagesController < Admin::ApplicationController

	def maping(message)
		message['receiver_emails'] = []
		message['receiver_ids'].each do |rec_id|
			message['receiver_emails'] << User.find(rec_id).email
		end
		message['sender_email'] = User.find(message['sender_id'].to_s).email
		message
	end

	def index
# <<<<<<< HEAD
# 		# (Message.all.desc(:created_at).page(page).per(per_page) || []).map{ |e| maping(e) }
# 		#@messages = ErrorEnum::MessgaeNotFound if @messages.empty?
# 		render_json true do
# 			auto_paginate Message.all.desc(:created_at) do |messages|
# 				(messages || []).map{ |e| maping(e) }
# 			end
# 		end
# =======
		@messages = Message.all.desc(:created_at)
		@show_messages = auto_paginate(@messages)
		@show_messages['data'] = @show_messages['data'].map{ |e| maping(e) }
		#@messages = ErrorEnum::MessgaeNotFound if @messages.empty?
		render_json_auto @show_messages

	end

	def count
		count = Message.count
		render_json_auto count
	end

	def show
		@message = Message.find_by_id(params[:id])
		@message = maping(@message) if @message.is_a? Message
		render_json_auto @message
	end

	def create
		@message = current_user.create_message(params[:message][:title],params[:message][:content],params[:message][:receiver])
		render_json @message.save do @message.as_retval end
	end

	def update
		@message = current_user.update_message(params[:id], params[:message])
		render_json @message.save do @message.as_retval end
	end

	def destroy
		@message = current_user.destroy_message(params[:id])
		render_json_auto @message
	end

end