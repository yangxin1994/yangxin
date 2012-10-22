
class Admin::UsersController < Admin::ApplicationController
#--
# ************** Quill Admin Manage User ************************************
#++
	
	@@user_attrs_filter = %w(_id email role status username true_name identity_card company birthday gender address phone postcode black white new_password lock)

	# GET /admin/users
	# GET /admin/users.json
	def index
		
		if !params[:email].nil? then
			@users = User.where(email: params[:email]).desc(:status, :created_at).page(page).per(per_page) || []
		elsif !params[:true_name].nil? then	
			@users = User.where(true_name: params[:true_name]).desc(:status, :created_at).page(page).per(per_page) || []
		elsif !params[:username].nil? then
			filter = params[:username].to_s.gsub(/[*]/, ' ')
			@users = User.where(username: /.*#{filter}.*/).desc(:status, :created_at).page(page).per(per_page) || []
		else
			@users = User.normal_list.desc(:status, :created_at).page(page).per(per_page) || []
		end			

		respond_to do |format|
			format.html # index.html.erb
			format.json { render_json_auto @users, :only => @@user_attrs_filter }
		end
	end

	def count
		render_json_auto User.normal_list.count
	end

	def email_count
		render_json_auto User.where(email: params[:email]).count
	end

	def true_name_count
		render_json_auto User.where(true_name: params[:true_name]).count
	end
	
	def username_count
		filter = params[:username].to_s.gsub(/[*]/, ' ')
		render_json_auto User.where(username: /.*#{filter}.*/).count
	end
	# GET /admin/users/1 
	# GET /admin/users/1.json
	def show
		@user = User.where(_id: params[:id]).first
		@user = ErrorEnum::USER_NOT_EXIST unless @user

		respond_to do |format|
			format.html # show.html.erb
			format.json { render_json_auto @user, :only => @@user_attrs_filter}
		end
	end

	# GET /admin/users/1/edit
	def edit
		@user = User.where(_id: params[:id]).first
		@user = ErrorEnum::USER_NOT_EXIST unless @user

		respond_to do |format|
			format.html # show.html.erb
			format.json { render_json_auto @user, :only => @@user_attrs_filter }
		end
	end

	# PUT /admin/users/1
	# PUT /admin/users/1.json
	def update

		if !params[:recovery].nil? && %w(true false).include?(params[:recovery].to_s) then
			@user = User.update_user(params[:id], {"status" => 0}) if params[:recovery] == "true"
			@user = User.update_user(params[:id], {"status" => -1}) if params[:recovery] == "false"
		else
			@user = User.update_user(params[:id], params[:user])
		end

		respond_to do |format|
			format.html { redirect_to @user} if @user.instance_of?(User)
			format.html { render action: "edit" } if !@user.instance_of?(User)
			format.json { render_json_auto @user, :only => @@user_attrs_filter }
		end
	end

	# DELETE /admin/users/1
	# DELETE /admin/users/1.json
	def destroy
		@user = User.update_user(params[:id], {"status" => -1})

		respond_to do |format|
			format.html { redirect_to users_url }
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
		@users = User.black_list.desc(:created_at).page(page).per(per_page)

		respond_to do |format|
			format.html # index.html.erb
			format.json { render_json_auto @users, :only => @@user_attrs_filter }
		end
	end

	def blacks_count
		render_json_auto User.black_list.count
	end

	# GET /admin/users/whites(.json)
	def whites
		@users = User.white_list.desc(:created_at).page(page).per(per_page)

		respond_to do |format|
			format.html # index.html.erb
			format.json { render_json_auto @users, :only => @@user_attrs_filter }
		end
	end

	def whites_count
		render_json_auto User.white_list.count
	end

	def deleteds
		@users = User.deleted_users.desc(:created_at).page(page).per(per_page)

		respond_to do |format|
			format.html # index.html.erb
			format.json { render_json_auto @users, :only => @@user_attrs_filter }
		end
	end

	def deleteds_count
		render_json_auto User.deleted_users.count
	end

	# GET /admin/users/1/black(.json)
	def black
		@user = User.change_black_user(params[:id])

		respond_to do |format|
			format.html {render action => 'show', :id => @user.id.to_s }
			format.json { render_json_auto @user, :only => @@user_attrs_filter }
		end
	end

	# GET /admin/users/1/white(.json)
	def white
		@user = User.change_white_user(params[:id])

		respond_to do |format|
			format.html {render action => 'show', :id => @user.id.to_s }
			format.json { render_json_auto @user, :only => @@user_attrs_filter }
		end
	end

	#POST
	def change_role_status
		retval = User.change_user_role_status(params[:id], params[:role_status])

		respond_to do |format|
			format.html {render action => 'show', :id => params[:id] }
			format.json { render_json_auto retval }
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
			format.json { render_json_auto @user, :only => @@user_attrs_filter }
		end
	end

end