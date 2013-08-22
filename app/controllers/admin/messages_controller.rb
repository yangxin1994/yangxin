class Admin::MessagesController < Admin::AdminController

	layout 'admin_new'

	before_filter :get_client

	def get_client
		@client = BaseClient.new(session_info, "/admin/messages")
	end

	# ************************
	
	# GET
	def index
		hash_params={:page=> page, :per_page => per_page}
		hash_params.merge!({:receiver_email => params[:receiver_email]}) if params[:receiver_email]
		@messages = @client._get(hash_params)
		_sign_out and return if @messages.require_login?

		respond_to do |format|
			format.html
			format.json { render json: @messages}
		end
	end

	def show
		@message = @client._get({},"/#{params[:id]}")
		respond_to do |format|
			format.html
			format.json { render json: @message}
		end
	end

	#post
	def create
		receiver = params[:receiver].split(',').each{|v| v.strip!}
		@result = @client._post({
		:message => {
				:title => params[:title],
				:content => params[:content],
				:receiver => receiver
			}
		})

		render_result
	end

	# put
	def update
		receiver = params[:receiver].split(',').each{|v| v.strip!}
		@result = @client._put({
		:message => {
				:title => params[:title],
				# :receiver => receiver,
				:content => params[:content]
			}
		}, "/#{params[:id]}")
		render_result
	end

	#delete
	def destroy
		@result = @client._delete({}, "/#{params[:id]}")
		render_result
	end

# old
	def maping(message)
		message['receiver_emails'] = []
		message['receiver_ids'].each do |rec_id|
			receiver = User.find_by_id_including_deleted(rec_id)
			message['receiver_emails'] << receiver.email if receiver
		end
		
		sender=User.find_by_id_including_deleted(message['sender_id'].to_s)
		message['sender_email'] = sender.email if sender
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