# coding: utf-8

class SystemUsersController < ApplicationController

	before_filter :require_admin
 
	# GET /system_users
	# GET /system_users.json
	def index
		if !params[:system_user_type].nil? then
			if !params[:lock].nil? then
				if params[:lock].to_s.strip == "true" then
					@system_users = SystemUser.list_by_type_and_lock(params[:system_user_type], true)
				elsif params[:lock].to_s.strip == "false" then
					@system_users = SystemUser.list_by_type_and_lock(params[:system_user_type], false)
				end
			else
				@system_users = SystemUser.list_by_type(params[:system_user_type])	
			end
		else
			@system_users = SystemUser.all.desc(:updated_at)
		end

		@system_users = slice((@system_users || []), params[:page], params[:per_page])

		respond_to do |format|
			format.html # index.html.erb
			format.json { render json: @system_users }
		end
	end
	
	# GET /system_users/1 
	# GET /system_users/1.json
	def show
		@system_user = SystemUser.find_by_id(params[:id])

		respond _to do |format|
			format.html # show.html.erb
			format.json { render json: @system_user }
		end
	end

	# GET /system_users/new
	# GET /system_users/new.json
	def new
		@system_user = SystemUser.new

		respond_to do |format|
			format.html # new.html.erb
			format.json { render json: @system_user }
		end
	end

	# GET /system_users/1/edit
	def edit
		@system_user = SystemUser.find_by_id(params[:id])

		respond _to do |format|
			format.html # show.html.erb
			format.json { render json: @system_user }
		end
	end
	
	# POST /system_users
	# POST /system_users.json
	def create
		@system_user = SystemUser.create_system_user(params[:system_user])	
			
		respond_to do |format|
			format.html  if @system_user.instance_of?(SystemUser)
			format.html { render action: "new" } if !@system_user.instance_of?(SystemUser)
			format.json { render :json => @system_user}
		end
	end

	# PUT /system_users/1
	# PUT /system_users/1.json
	def update
		@system_user = SystemUser.update_system_user(params[:id], params[:system_user])

		respond_to do |format|
			format.html { redirect_to @system_user} if @system_user.instance_of?(SystemUser)
			format.html { render action: "edit" } if !@system_user.instance_of?(SystemUser)
			format.json { render :json => @system_user }
		end
	end

	# POST /system_users/lock
	# POST /system_users/lock.json
	def lock
		@system_user = SystemUser.update_system_user(params[:id], {"lock" => true})

		respond_to do |format|
			format.html { redirect_to @system_user} if @system_user.instance_of?(SystemUser)
			format.html { render action: "edit" } if !@system_user.instance_of?(SystemUser)
			format.json { render :json => @system_user }
		end
	end

	# POST /system_users/unlock
	# POST /system_users/unlock.json
	def unlock
		@system_user = SystemUser.update_system_user(params[:id], {"lock" => false})

		respond_to do |format|
			format.html { redirect_to @system_user } if @system_user.instance_of?(SystemUser)
			format.html { render action: "edit" } if !@system_user.instance_of?(SystemUser)
			format.json { render :json => @system_user }
		end
	end
	
end