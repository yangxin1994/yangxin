
class Admin::UsersController < Admin::ApplicationController
	before_filter :check_user_existence, :only => [:show, :edit, :set_color, :set_role, :set_lock, :destroy, :update, :system_pwd, :recover, :add_point]
#--
# ************** Quill Admin Manage User ************************************
#++
	
	@@user_attrs_filter = %w(_id email color role status username full_name identity_card company birthday gender address phone postcode black white new_password lock color point)

	def check_user_existence
		@user = User.find_by_id_including_deleted(params[:id])
		render_json_auto(ErrorEnum::USER_NOT_EXIST) and return if @user.nil?
	end

	# GET /admin/users
	# GET /admin/users.json
	def index
		if !params[:email].nil? then
			@users = User.where(email: params[:email]).desc(:status, :created_at)
		elsif !params[:full_name].nil? then	
			@users = User.where(full_name: params[:full_name]).desc(:status, :created_at)
		elsif !params[:username].nil? then
			filter = params[:username].to_s.gsub(/[*]/, ' ')
			@users = User.where(username: /.*#{filter}.*/).desc(:status, :created_at)
		else
			@users = User.normal_list.where(:role.lt => 15).desc(:status, :created_at)
		end			

		render_json_auto (auto_paginate(@users)) and return
	end

	# GET /admin/users/1 
	# GET /admin/users/1.json
	def show
		respond_to do |format|
			format.json { render_json_auto @user, :only => @@user_attrs_filter}
		end
	end

	# GET /admin/users/1/edit
	def edit
		respond_to do |format|
			format.json { render_json_auto @user, :only => @@user_attrs_filter }
		end
	end

	# PUT /admin/users/1
	# PUT /admin/users/1.json
	def update
		retval = @user.update_user(params[:user])
		respond_to do |format|
			format.json { render_json_auto retval }
		end
	end

	# DELETE /admin/users/1
	# DELETE /admin/users/1.json
	def destroy
		render_json_auto @user.remove_user
	end

	# PUT
	def recover
		render_json_auto @user.recover
	end


	def lottery_codes
		@user = User.find_by_id params[:id]
		render_json(@user.is_a? User) do |s|
			if s
				auto_paginate @user.lottery_codes.desc(:created_at)
			else
				{
					:error_code => ErrorEnum::USER_NOT_EXIST,
					:error_message => "User not exist"
				}
			end
		end
	end

	def orders
		@user = User.find_by_id params[:id]
		render_json(@user.is_a? User) do |s|
			if s
				params[:scope] = "all" if params[:scope].blank?	
				auto_paginate @user.orders.send(params[:scope].to_s)
			else
				{
					:error_code => ErrorEnum::USER_NOT_EXIST,
					:error_message => "User not exist"
				}
			end
		end
	end
	#--
	# **************************************
	# Black List Operate 
	# **************************************
	#++

	# GET /admin/users/blacks(.json)
	def blacks
		@users = User.black_list.desc(:created_at)

		respond_to do |format|
			format.html # index.html.erb
			format.json { render_json_auto auto_paginate(@users)}
		end
	end

	# GET /admin/users/whites(.json)
	def whites
		@users = User.white_list.desc(:created_at)

		respond_to do |format|
			format.html # index.html.erb
			format.json { render_json_auto auto_paginate(@users)}
		end
	end

	def deleteds
		@users = User.deleted_users.desc(:created_at)

		respond_to do |format|
			format.html # index.html.erb
			format.json { render_json_auto auto_paginate(@users)}
		end
	end

	def set_role
		# admin can only set the latter 4 digits of the role field
		retval = @user.set_role(params[:role].to_i)
		respond_to do |format|
			format.json { render_json_auto retval }
		end
	end

	def set_color
		retval = @user.set_color(params[:color].to_i)
		respond_to do |format|
			format.json { render_json_auto retval }
		end
	end

	def set_lock
		retval = @user.set_lock(params[:lock].to_s=='true')
		respond_to do |format|
			format.json { render_json_auto retval }
		end
	end

	def add_point
		@reward_log = @current_user.operate_point(params[:point], params[:cause_desc], params[:id])
		render_json(@reward_log.valid?) do
			@reward_log.as_retval
		end
	end

	def system_pwd
		@user.change_to_system_password

		respond_to do |format|
			format.json { render_json_auto @user, :only => @@user_attrs_filter }
		end
	end

	# add diff class system_user interface
	def create
		retval = @current_user.create_user(params[:user])
		respond_to do |format|
			format.json { render_json_auto retval }
		end
	end

	def list_by_role
		role = params[:role].to_i
		if (role > 0) && (role < 64)
			# not include role =0 

			users = User.where(:role.gt => 0).desc(:lock, :created_at).to_a
			# logger.debug '+++++++++++'
			# logger.debug users.length
			users.select! do |u|
				u.role.to_i & role > 0
			end
			# logger.debug users.to_a.length

			# super_admin can search all with role in fix.
			# admin all, but super_admin and admin.
			users.select!{|u| u.role.to_i < 15} if !@current_user.is_super_admin
		elsif role==0
			# only for role=0
			users = User.where(role: role).desc(:lock, :created_at).to_a
		else
			# all of user
			users = User.all.desc(:lock, :created_at).to_a
			users.select!{|u| u.role.to_i < 15} if !@current_user.is_super_admin
		end

		# display delete users if params[:deleted]
		users.select!{|u| u.status >= 0} if params[:deleted] && params[:deleted].to_s == 'false'

		paginated_users = auto_paginate(users)

	    render_json_auto paginated_users
	end

	def get_introduced_users
		user = User.find_by_id_including_deleted(params[:id])
		render_json_e(ErrorEnum::USER_NOT_EXIST) if user.nil?

		introduced_users = auto_paginate user.get_introduced_users
		render_json_auto(introduced_users) and return
	end
end