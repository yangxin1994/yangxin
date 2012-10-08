class Admin::MessagesController < Admin::ApplicationController

	before_filter :require_sign_in

	def maping(message)
		message['receiver_emails'] = []
		message['receiver_ids'].each do |rec_id|
			message['receiver_emails'] << User.find(rec_id).email
		end
		message['sender_email'] = User.find(message['sender_id'].to_s).email
		message
	end

	def index
		@messages = (Message.all.page(page).per(per_page) || []).map{ |e| maping(e) }
		#@messages = ErrorEnum::MessgaeNotFound if @messages.empty?
		render_json_auto @messages
	end

	def count
		count = Message.count
		render_json_auto count
	end

	def show
		@message = Message.find_by_id(params[:id])
		@message = maping(@message) if @message
		render_json_auto @message
	end

	def create
		@message = current_user.create_message(params[:message][:title],params[:message][:content],params[:message][:receiver])
		respond_and_render_json @message.save do @message.as_retval end
	end

	def update
		@message = current_user.update_message(params[:id], params[:message])
		respond_and_render_json @message.save do @message.as_retval end
	end

	def destroy
		@message = current_user.destroy_message(params[:id])
		render_json_auto @message
	end
							 
end