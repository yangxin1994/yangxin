# coding: utf-8

class Admin::SystemUsersController < Admin::ApplicationController

	# before_filter :require_admin

	@@system_user_attrs_filter = %w(_id system_user_type true_name email username lock created_at updated_at)
 
	# all the interfaces should be able to realized by the interfaces in the admin::users_controller
=begin
	# GET /admin/system_users
	# GET /admin/system_users.json
	def index
		users = User.list_system_user(params[:role], params[:lock])
		respond_to do |format|
			format.json { render_json_auto @users, :only => @@system_user_attrs_filter }
		end
	end

	def count
		render_json_auto User.list_system_user(params[:role], params[:lock]).length
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
=end
end