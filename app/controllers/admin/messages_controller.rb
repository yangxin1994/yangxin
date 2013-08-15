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

end