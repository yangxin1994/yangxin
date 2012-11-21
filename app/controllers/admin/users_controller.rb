
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
		if !params[:role].nil? then
			role_params=params[:role].to_i
			roles = []
			5.downto(0).each do |i|
				if role_params / 2**i == 1 
					roles << 2**i
					role_params %= 2**i
				end
			end
			@users = User.list_by_roles(roles)
		elsif !params[:email].nil? then
			@users = User.where(email: params[:email]).desc(:status, :created_at)
		elsif !params[:full_name].nil? then	
			@users = User.where(full_name: params[:full_name]).desc(:status, :created_at)
		elsif !params[:username].nil? then
			filter = params[:username].to_s.gsub(/[*]/, ' ')
			@users = User.where(username: /.*#{filter}.*/).desc(:status, :created_at)
		else
			@users = User.normal_list.desc(:status, :created_at)
		end			

		if !params[:role].nil? then
			render_json_auto(auto_paginate(@users){@users.slice((page-1)*per_page, per_page)}) and return
		else
			render_json_auto (auto_paginate(@users)) and return
		end
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
		retval = @user.update_attributes({"status" => -1})
		respond_to do |format|
			format.json { render_json_auto retval }
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
		users = User.where(role: params[:role].to_i).desc(:lock, :created_at)
		render_json_auto auto_paginate(users)
	end
end