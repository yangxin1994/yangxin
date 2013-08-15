class Admin::UsersController < Admin::AdminController

	layout 'layouts/admin_new'

	before_filter :get_client

	def get_client
		@client = BaseClient.new(session_info, "/admin/users")
    @sample_client = Admin::SampleClient.new(session_info)
	end

	# ****************************

	def index
		params_hash ={:page => page,:per_page => per_page}
		if params[:role]
			params_hash.merge!({:role => params[:role]})
			params_hash.merge!({:deleted => params[:deleted]}) if params[:deleted]
			@users = @client._get(params_hash, "/list_by_role")
		else
			params_hash.merge!({:username => params[:username]}) if params[:username]
			params_hash.merge!({:email => params[:email]}) if params[:email]
			params_hash.merge!({:full_name => params[:full_name]}) if params[:full_name]
			params_hash.merge!({:mobile => params[:mobile]}) if params[:mobile]
			if params[:include_block] == '1'
				params_hash.merge!({:is_block => true})
			else
				params_hash.merge!({:is_block => false})
			end
			@users = @sample_client.get_samples(params_hash)
		end

		_sign_out and return if @users.require_admin?

		respond_to do |format|
			format.html
			format.json { render json: @users}
		end
	end

	def create
		if !params[:password].nil? then
			@result = @client._post(
				{
					:user => {
							email: params[:email],
							full_name: params[:full_name],
							password: params[:password],
							role: params[:system_user_type]
						}
				})
		else
			@result = @client._post(
				{
					:user => {
							email: params[:email],
							full_name: params[:full_name],
							role: params[:system_user_type]
						}
				})
		end
		render_result
	end

	#GET
	def blacks
		@users = @client._get({:page => page,:per_page => per_page}, '/blacks')
		_sign_out and return if @users.require_admin?
		respond_to do |format|
			format.html
			format.json { render json: @users}
		end
	end

	#GET
	def whites
		@users = @client._get({:page => page,:per_page => per_page}, '/whites')
		_sign_out and return if @users.require_admin?
		respond_to do |format|
			format.html
			format.json { render json: @users}
		end
	end

	#GET
	def deleted
		@users = @client._get({:page => page,:per_page => per_page}, '/deleteds')
		_sign_out and return if @users.require_admin?
		respond_to do |format|
			format.html
			format.json { render json: @users}
		end
	end

	def show
		@user = @client._get({}, "/#{params[:id]}")
		# if user who is not super admin wants to get a admin user info,
		#  replace to sign in page.
		_sign_out and return if @user.value['role'].to_i >= 16 && !has_role(32)
		respond_to do |format|
			format.html
			format.json { render json: @user}
		end
	end

	# def create
	# end

	def update
		@result = @client._put({
				:user => params[:user]
			}, "/#{params[:id]}")
		render_result
	end

	def destroy
		@result = @client._delete({}, "/#{params[:id]}")
		render_result
	end

	# ******************

	#PUT
	def recover
		@result = @client._put({}, "/#{params[:id]}/recover")
		render_result
	end

	#PUT
	def set_role
		@result = @client._put(
			{
				:role => params[:role]
			}, "/#{params[:id]}/set_role")
		render_result
	end

	#PUT
	def set_color
		@result = @client._put(
			{
				:color => params[:color]
			}, "/#{params[:id]}/set_color")
		render_result
	end

	#PUT
	def set_lock
		@result = @client._put({lock: params[:lock]}, "/#{params[:id]}/set_lock")
		render_result
	end

	#PUT
	def reset_password
		@result = @client._put({}, "/#{params[:id]}/system_pwd")
		render_result
	end

	# PUT
	def add_point
		@result = @client._put({point: params[:point],
			cause_desc: params[:cause_desc]},
			"/#{params[:id]}/add_point"
		 )
		render_result
	end

	#GET /admin/users/:id/rewards
	def rewards
		@orders = @client._get(
			{
				page: page,
				per_page: per_page,
				scope: params[:scope]
			},
			"/#{params[:id]}/orders"
		)
		respond_to do |format|
			format.html
			format.json { render json: @orders}
		end
	end

	#GET /admin/users/:id/point_logs
	def point_logs
		@point_logs = @client._get(
			{
				page: page,
				per_page: per_page,
				scope: params[:scope]
			},
			"/#{params[:id]}/point_logs"
		)
		respond_to do |format|
			format.html
			format.json { render json: @point_logs}
		end
	end

	#GET /admin/users/:id/lottery_record
	def lottery_record
		@lottery_codes = @client._get(
			{
				page: page,
				per_page: per_page,
				scope: params[:scope]
			},
			"/#{params[:id]}/lottery_codes"
		 )
		respond_to do |format|
			format.html
			format.json { render json: @lottery_codes}
		end
	end

	#GET /admin/users/:id/lottery_record
	def introduced_users
		@users = @client._get(
			{
				page: page,
				per_page: per_page
			},
			"/#{params[:id]}/get_introduced_users"
		 )

		respond_to do |format|
			format.html
			format.json { render json: @users}
		end
	end

end
