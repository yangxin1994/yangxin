
class Admin::UsersController < Admin::ApplicationController
#--
# **************Quill Admin Manage User************************************
#++
	
	@@user_attrs_filter = %w(_id email username true_name birthday gender address phone postcode black white tmp_password)

	before_filter :require_admin

	# GET /admin/users
	# GET /admin/users.json
	def index
		
		if !params[:email].nil? then
			@users = User.where(email: params[:email]).to_a
		elsif !params[:username].nil? then
			@users = User.where(username: params[:username]).to_a
		elsif !params[:true_name].nil? then
			@users = User.where(true_name: params[:true_name]).to_a
		else
			@users = User.all.to_a
		end			
		
		@users.sort!{|v1, v2| v2.updated_at <=> v1.updated_at} if @users.count > 1
		@users =  slice((@users || []), params[:page], params[:per_page])

		respond_to do |format|
			format.html # index.html.erb
			format.json { render json: @users,
				:only => @@user_attrs_filter }
		end
	end
	
	# GET /admin/users/1 
	# GET /admin/users/1.json
	def show
		@user = User.find_by_id(params[:id])

		respond_to do |format|
			format.html # show.html.erb
			format.json { render json: @user, 
				:only => @@user_attrs_filter}
		end
	end

	# GET /admin/users/1/edit
	def edit
		@user = User.find_by_id(params[:id])

		respond_to do |format|
			format.html # show.html.erb
			format.json { render json: @user, 
				:only => @@user_attrs_filter }
		end
	end

	# PUT /admin/users/1
	# PUT /admin/users/1.json
	def update
		@user = User.update_user(params[:id], params[:user])

		respond_to do |format|
			format.html { redirect_to @user} if @user.instance_of?(User)
			format.html { render action: "edit" } if !@user.instance_of?(User)
			format.json { render :json => @user, 
				:only => @@user_attrs_filter }
		end
	end

	#--
	# **************************************
	# Black List Operate 
	# **************************************
	#++

	# GET /admin/users/blacks
	def blacks
		@users = User.black_list.to_a
		@users.sort!{|v1, v2| v2.updated_at <=> v1.updated_at} if @users.count > 1

		@users =  slice((@users || []), params[:page], params[:per_page])

		respond_to do |format|
			format.html # index.html.erb
			format.json { render json: @users, 
				:only => @@user_attrs_filter }
		end
	end

	# GET /admin/users/whites
	def whites
		@users = User.white_list.to_a
		@users.sort!{|v1, v2| v2.updated_at <=> v1.updated_at} if @users.count > 1

		@users =  slice((@users || []), params[:page], params[:per_page])

		respond_to do |format|
			format.html # index.html.erb
			format.json { render json: @users, 
				:only => @@user_attrs_filter }
		end
	end

	# GET /admin/users/1/black
	def black
		@user = User.change_black_user(params[:id])

		respond_to do |format|
			format.html {render action => 'show', :id => @user.id.to_s }
			format.json { render json: @user, 
				:only => @@user_attrs_filter }
		end
	end

	# GET /admin/users/1/white
	def white
		@user = User.change_white_user(params[:id])

		respond_to do |format|
			format.html {render action => 'show', :id => @user.id.to_s }
			format.json { render json: @user, 
				:only => @@user_attrs_filter }
		end
	end

	#--
	# ***********************************
	#  Change password to system
	# ************************************
	#++

	# GET /admin/users/1/system_pwd
	def system_pwd
		@user = User.change_to_system_password(params[:id])

		respond_to do |format|
			format.html {render action => 'show', :id => @user.id.to_s }
			format.json { render json: @user, 
				:only => @@user_attrs_filter }
		end
	end

end