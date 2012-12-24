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
		@messages = Message.all.desc(:created_at)
		if params[:receiver_email]
			@messages = @messages.to_a.select{|elem| (elem.receiver.blank? || elem.receiver.include?(User.find_by_email(params[:receiver_email])))}
		end

		@show_messages = auto_paginate(@messages)
		@show_messages['data'] = @show_messages['data'].map{ |e| maping(e) }
		render_json_auto @show_messages	and return
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
		render_json_auto @message.save do @message.as_retval end
	end

	def update
		@message = current_user.update_message(params[:id], params[:message])
		render_json_auto @message
	end

	def destroy
		@message = current_user.destroy_message(params[:id])
		render_json_auto @message
	end

end