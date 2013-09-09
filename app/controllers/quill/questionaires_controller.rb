# finish migrating
require 'error_enum'
class Quill::QuestionairesController < Quill::QuillController

	# before_filter :get_ws_client, :except => [:show]

	before_filter :require_sign_in, :only => [:index, :show]

	before_filter :ensure_survey, :only => [:show]

	def get_ws_client
		@ws_client = Quill::SurveyClient.new(session_info)
	end
	
	# PAGE: list survey
	# GET
	def index
		# add stars survey in Index action
		@stars = params[:stars].to_s == "true"
		@status = params[:status] || 3
		if !params[:title].nil?
			@surveys = Survey.search_title(params[:title], current_user)
		elsif params[:stars].nil?
			@surveys = current_user.surveys.list(@status)
		else
			@surveys = current_user.surveys.stars
		end	
		@surveys = auto_paginate @surveys
		respond_to do |format|
			format.html { }
			format.json { render json: @surveys}
		end
	end

	# PAGE
	def new
		@survey = Survey.new
		@survey.user = current_user
		if current_user.is_admin?
			@survey.status = Survey::PUBLISHED
		else
			@survey.style_setting["has_advertisement"] = false
		end
		@survey.save
		@survey.create_default_reward_scheme
		redirect_to questionaire_path(@survey._id) and return
	end

	# AJAX: clone survey
	def clone
		@survey = Survey.find_by_id(params[:id])
		render_json_e ErrorEnum::SURVEY_NOT_EXIST and return if @survey.nil?
		new_survey = @survey.clone_survey(current_user, params[:title])
		render_json_auto(new_survey.serialize) and return
	end

	# PAGE: show and edit survey
	def show
		@locked = (!current_user.is_admin? && @survey.publish_status == 8) 
	end

	# AJAX: delete survey
	def destroy
		@survey = Survey.find_by_id(params[:questionaire_id])
		render_json_e ErrorEnum::SURVEY_NOT_EXIST and return if @survey.nil?
		retval = @survey.delete(current_user)
		render_json_auto(retval) and return
	end

	# PUT
	def recover
		@survey = Survey.find_by_id(params[:id])
		render_json_e ErrorEnum::SURVEY_NOT_EXIST and return if @survey.nil?
		render_json_auto @survey.recover(current_user)
	end

	#GET
	def remove
		@survey = Survey.find_by_id(params[:id])
		render_json_e ErrorEnum::SURVEY_NOT_EXIST and return if @survey.nil?
		render_json_auto @survey.clear(current_user)
	end

	# get
	def update_star
		@survey = Survey.find_by_id(params[:id])
		render_json_e ErrorEnum::SURVEY_NOT_EXIST and return if @survey.nil?
		render_json_auto @survey.update_star(params[:is_star].to_s == "true")
	end

	# AJAX: publish survey
	def publish
		@survey = Survey.find_by_id(params[:id])
		render_json_e ErrorEnum::SURVEY_NOT_EXIST and return if @survey.nil?
		render_json_auto @survey.publish(current_user)
	end
	
	# AJAX: set deadline
	def deadline
		@survey = Survey.find_by_id(params[:id])
		render_json_e ErrorEnum::SURVEY_NOT_EXIST and return if @survey.nil?
		render_json_auto @survey.publish(current_user)
		render_json_auto @survey.update_deadline(params[:deadline].to_i)
	end

	# AJAX: close a published survey
	def close
		@survey = Survey.find_by_id(params[:id])
		render_json_e ErrorEnum::SURVEY_NOT_EXIST and return if @survey.nil?
		render_json_auto @survey.close(current_user)
	end
end
