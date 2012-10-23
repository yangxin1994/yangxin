# coding: utf-8

class Admin::SystemUsersController < Admin::ApplicationController

	# before_filter :require_admin

	@@system_user_attrs_filter = %w(_id system_user_type true_name email username lock created_at updated_at)
 
	# GET /admin/system_users
	# GET /admin/system_users.json
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

			@system_users = slice((@system_users || []), page, per_page)
		else
			@system_users = SystemUser.all.desc(:created_at).page(page).per(per_page)
		end

		respond_to do |format|
			format.html # index.html.erb
			format.json { render_json_auto @system_users, 
				:only => @@system_user_attrs_filter }
		end
	end

	def count
		render_json_auto SystemUser.count
	end
	
	# GET /admin/system_users/1 
	# GET /admin/system_users/1.json
	def show
		@system_user = SystemUser.find_by_id(params[:id])

		respond_to do |format|
			format.html # show.html.erb
			format.json { render_json_auto @system_user,
				:only => @@system_user_attrs_filter }
		end
	end

	# GET /admin/system_users/new
	# GET /admin/system_users/new.json
	def new
		@system_user = SystemUser.new

		respond_to do |format|
			format.html # new.html.erb
			format.json { render_json_auto @system_user,
				:only => @@system_user_attrs_filter }
		end
	end

	# GET /admin/system_users/1/edit
	def edit
		@system_user = SystemUser.find_by_id(params[:id])

		respond _to do |format|
			format.html # show.html.erb
			format.json { render_json_auto @system_user,
				:only => @@system_user_attrs_filter }
		end
	end
	
	# POST /admin/system_users
	# POST /admin/system_users.json
	def create
		@system_user = SystemUser.create_system_user(params[:system_user])	
			
		respond_to do |format|
			format.html  if @system_user.instance_of?(SystemUser)
			format.html { render action: "new" } if !@system_user.instance_of?(SystemUser)
			format.json { render_json_auto @system_user, 
				:only => @@system_user_attrs_filter}
		end
	end

	# PUT /admin/system_users/1
	# PUT /admin/system_users/1.json
	def update
		@system_user = SystemUser.update_system_user(params[:id], params[:system_user])

		respond_to do |format|
			format.html { redirect_to @system_user} if @system_user.instance_of?(SystemUser)
			format.html { render action: "edit" } if !@system_user.instance_of?(SystemUser)
			format.json { render_json_auto @system_user,
				:only => @@system_user_attrs_filter }
		end
	end

	# POST /admin/system_users/:id/lock
	# POST /admin/system_users/:id/lock.json
	def lock
		@system_user = SystemUser.update_lock(params[:id], true)

		respond_to do |format|
			format.html { redirect_to @system_user} if @system_user.instance_of?(SystemUser)
			format.html { render action: "edit" } if !@system_user.instance_of?(SystemUser)
			format.json { render_json_auto @system_user,
				:only => @@system_user_attrs_filter }
		end
	end

	# POST /admin/system_users/:id/unlock
	# POST /admin/system_users/:id/unlock.json
	def unlock
		@system_user = SystemUser.update_lock(params[:id], false)

		respond_to do |format|
			format.html { redirect_to @system_user } if @system_user.instance_of?(SystemUser)
			format.html { render action: "edit" } if !@system_user.instance_of?(SystemUser)
			format.json { render_json_auto @system_user, 
				:only => @@system_user_attrs_filter }
		end
	end

	# add diff class systemuser interface
	def answer_anuditors
		render_json_auto AnswerAuditor.all.desc(:lock, :created_at).page(page).per(per_page)
	end

	def answer_anuditors_count
		render_json_auto AnswerAuditor.count
	end

	def survey_auditors
		render_json_auto SurveyAuditor.all.desc(:created_at) .page(page).per(per_page)
	end

	def survey_auditors_count
		render_json_auto SurveyAuditor.count
	end 
	
	def entry_clerks
		render_json_auto EntryClerk.all.desc(:created_at) .page(page).per(per_page)
	end

	def entry_clerks_count
		render_json_auto EntryClerk.count
	end 

	def interviewers
		render_json_auto Interviewer.all.desc(:created_at) .page(page).per(per_page)
	end

	def interviewers_count
		render_json_auto Interviewer.count
	end 
end