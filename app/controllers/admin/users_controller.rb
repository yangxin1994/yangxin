
class Admin::UsersController < Admin::ApplicationController
	before_filter :check_user_existence, :only => [:show, :edit, :set_color, :set_role, :set_lock, :destroy, :update, :system_pwd]
#--
# ************** Quill Admin Manage User ************************************
#++
	
	@@user_attrs_filter = %w(_id email color role status username full_name identity_card company birthday gender address phone postcode black white new_password lock color)

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
			@users = User.normal_list.desc(:status, :created_at)
		end			

		render_json_auto(auto_paginate(@users)) and return
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
		@user.update_attributes({"status" => -1})
		respond_to do |format|
			format.json { render_json_auto @user }
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
		@user.set_role({"role" => params[:role].to_i & 15})
		respond_to do |format|
			format.json { render_json_auto @user, :only => @@user_attrs_filter }
		end
	end

	def set_color
		@user.set_color(params[:color].to_i)
		respond_to do |format|
			format.json { render_json_auto @user, :only => @@user_attrs_filter }
		end
	end

	def set_lock
		@user.set_lock(params[:lock])
		respond_to do |format|
			format.json { render_json_auto @user, :only => @@user_attrs_filter }
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
		if role > 0
			users = User.where(:role.gt => 0).desc(:lock, :created_at).to_a
			logger.debug '+++++++++++'
			logger.debug users.length
			users.select! do |u|
				u.role.to_i & role > 0
			end
			logger.debug users.to_a.length
		else
			users = User.where(role: role).desc(:lock, :created_at).to_a
		end
		# users = User.where(role: params[:role].to_i).desc(:lock, :created_at)
		paginated_users = auto_paginate(users) do |u|
			u.slice((page - 1) * per_page, per_page)
    end
    render_json_auto paginated_users
	end
end