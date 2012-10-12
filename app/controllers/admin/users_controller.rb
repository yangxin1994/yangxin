
class Admin::UsersController < Admin::ApplicationController
#--
# **************Quill Admin Manage User************************************
#++
	
	@@user_attrs_filter = %w(_id email status username true_name birthday gender address phone postcode black white)

	# GET /admin/users
	# GET /admin/users.json
	def index
		
		if !params[:email].nil? then
			@users = User.where(email: params[:email]).to_a
		elsif !params[:true_name].nil? then	
			@users = User.where(true_name: params[:true_name]).to_a
		elsif !params[:username].nil? then
			filter = params[:username].to_s.gsub(/[*]/, ' ')
			@users = User.where(username: /.*#{filter}.*/).to_a
		else
			@users = User.all.to_a
		end			
		
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

		if !params[:recovery].nil? && %w(true false).include?(params[:recovery].to_s) then
			@user = User.update_user(params[:id], {"status" => 0}) if params[:recovery] == "true"
			@user = User.update_user(params[:id], {"status" => -1}) if params[:recovery] == "false"
		else
			params[:user].select!{|k,v| %w(birthday gender address phone postcode).include?(k.to_s)}
			@user = User.update_user(params[:id], params[:user])
		end

		respond_to do |format|
			format.html { redirect_to @user} if @user.instance_of?(User)
			format.html { render action: "edit" } if !@user.instance_of?(User)
			format.json { render :json => @user, 
				:only => @@user_attrs_filter }
		end
	end

	# DELETE /admin/users/1
	# DELETE /admin/users/1.json
	def destroy
		@user = User.update_user(params[:id], {"status" => -1})

		respond_to do |format|
			format.html { redirect_to users_url }
			format.json { render :json => @user }
		end
	end

	#--
	# **************************************
	# Black List Operate 
	# **************************************
	#++

	# GET /admin/users/blacks(.json)
	def blacks
		@users = User.black_list.to_a

		@users =  slice((@users || []), params[:page], params[:per_page])

		respond_to do |format|
			format.html # index.html.erb
			format.json { render json: @users, 
				:only => @@user_attrs_filter }
		end
	end

	# GET /admin/users/whites(.json)
	def whites
		@users = User.white_list.to_a

		@users =  slice((@users || []), params[:page], params[:per_page])

		respond_to do |format|
			format.html # index.html.erb
			format.json { render json: @users, 
				:only => @@user_attrs_filter }
		end
	end

	# GET /admin/users/1/black(.json)
	def black
		@user = User.change_black_user(params[:id])

		respond_to do |format|
			format.html {render action => 'show', :id => @user.id.to_s }
			format.json { render json: @user, 
				:only => @@user_attrs_filter }
		end
	end

	# GET /admin/users/1/white(.json)
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

	# GET /admin/users/1/system_pwd(.json)
	def system_pwd
		@user = User.change_to_system_password(params[:id])

		respond_to do |format|
			format.html {render action => 'show', :id => @user.id.to_s }
			format.json { render json: @user, 
				:only => @@user_attrs_filter }
		end
	end

end