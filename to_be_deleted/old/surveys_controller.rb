require 'array'
require 'error_enum'
require 'quill_common'
class SurveysController < ApplicationController
	before_filter :require_sign_in, :except => [:show, :list_surveys_in_community, :search_title]
	before_filter :check_survey_existence, :only => [:add_tag, :remove_tag, :update_deadline, :update_star]
	before_filter :check_normal_survey_existence, :except => [:new, :index, :list_surveys_in_community, :list_answered_surveys, :list_spreaded_surveys, :recover, :clear, :add_tag, :remove_tag, :show, :update_star, :search_title]
	before_filter :check_deleted_survey_existence, :only => [:recover, :clear]
	
	def check_survey_existence
		@survey = @current_user.is_admin? ? Survey.find_by_id(params[:id]) : @current_user.surveys.find_by_id(params[:id])
		if @survey.nil?
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::SURVEY_NOT_EXIST) and return }
			end
		end
	end

	def check_normal_survey_existence
		@survey = @current_user.is_admin? ? Survey.normal.find_by_id(params[:id]) : @current_user.surveys.normal.find_by_id(params[:id])
		if @survey.nil?
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::SURVEY_NOT_EXIST) and return }
			end
		end
	end

	def check_deleted_survey_existence
		@survey = @current_user.is_admin? ? Survey.deleted.find_by_id(params[:id]) : @current_user.surveys.deleted.find_by_id(params[:id])
		if @survey.nil?
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::SURVEY_NOT_EXIST) and return }
			end
		end
	end

	#*method*: get
	#
	#*url*: /surveys
	#
	#*description*: create a new empty survey
	#
	#*params*:
	#
	#*retval*:
	#* a Survey object with default meta data and empty survey_id
	#* ErrorEnum::EMAIL_NOT_EXIST
	def new
		survey = Survey.new
		survey.user = @current_user
		if @current_user.is_admin?
			survey.status = Survey::PUBLISHED
		else
			survey.style_setting["has_advertisement"] = false
		end
		survey.save
		survey.create_default_reward_scheme
		respond_to do |format|
			format.json	{ render_json_s(survey.serialize) and return }
		end
	end

	#*method*: put
	#
	#*url*: /surveys/:survey_id/save_meta_data
	#
	#*description*: save meta data of a survey
	#
	#*params*:
	#* survey: a Survey object
	#
	#*retval*:
	#* the Survey object: when meta data is successfully saved.
	#* ErrorEnum ::SURVEY_NOT_EXIST : when the survey does not exist
	#* ErrorEnum ::UNAUTHORIZED : when the survey does not belong to the current user
	def save_meta_data
		survey = @survey.save_meta_data(params[:survey])
		respond_to do |format|
			format.json	{ render_json_s(survey.serialize) and return }
		end
	end

	def show_style_setting
		style_setting = @survey.show_style_setting
		respond_to do |format|
			format.json	{ render_json_auto(style_setting) and return }
		end
	end

	def update_style_setting
		retval = @survey.update_style_setting(params[:style_setting])
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end

	def show_access_control_setting
		access_control_setting = @survey.show_access_control_setting
		respond_to do |format|
			format.json	{ render_json_auto(access_control_setting) and return }
		end
	end

	def update_access_control_setting
		retval = @survey.update_access_control_setting(params[:access_control_setting])
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end

	def show_quality_control
		retval = @survey.show_quality_control
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end

	def update_quality_control
		retval = @survey.update_quality_control(params[:quality_control_questions_type], params[:quality_control_questions_ids])
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end

	#*method*: delete
	#
	#*url*: /surveys/:survey_id
	#
	#*description*: destroy a survey
	#
	#*params*:
	#* survey_id: id of the survey to be deleted
	#
	#*retval*:
	#* true: when survey is successfully deleted.
	#* ErrorEnum ::SURVEY_NOT_EXIST : when the survey does not exist
	#* ErrorEnum ::UNAUTHORIZED : when the survey does not belong to the current user
	def destroy
		retval = @survey.delete(@current_user)
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end

	#*method*: get
	#
	#*url*: /surveys/:survey_id/recover
	#
	#*description*: recover a survey from trash
	#
	#*params*:
	#* survey_id: id of the survey to be recovered
	#
	#*retval*:
	#* true: when survey is successfully recovered.
	#* ErrorEnum ::SURVEY_NOT_EXIST : when the survey does not exist in the trash
	#* ErrorEnum ::UNAUTHORIZED : when the survey does not belong to the current user
	def recover
		retval = @survey.recover(@current_user)
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end

	#*method*: get
	#
	#*url*: /surveys/:survey_id/clear
	#
	#*description*: thoroughly destroy
	#
	#*params*:
	#* survey_id: id of the survey to be cleared
	#
	#*retval*:
	#* true: when survey is successfully cleared.
	#* ErrorEnum ::SURVEY_NOT_EXIST : when the survey does not exist in the trash
	#* ErrorEnum ::UNAUTHORIZED : when the survey does not belong to the current user
	def clear
		retval = @survey.clear(@current_user)
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end

	#*method*: get
	#
	#*url*: /surveys/:survey_id/clone?title=:title
	#
	#*description*: clone a survey
	#
	#*params*:
	#* survey_id: id of the survey to be deleted
	#* title: new title for the cloned survey. If set as empty string, the title of the cloned survey will be the same as the original survey
	#
	#*retval*:
	#* a Survey object: when survey is successfully cloned.
	#* ErrorEnum ::SURVEY_NOT_EXIST : when the survey does not exist
	#* ErrorEnum ::UNAUTHORIZED : when the survey does not belong to the current user
	def clone
		new_survey = @survey.clone_survey(@current_user, params[:title])
		respond_to do |format|
			format.json	{ render_json_auto(new_survey.serialize) and return }
		end
	end

	#*method*: get
	#
	#*url*: /surveys/:survey_id
	#
	#*description*: obtain a survey
	#
	#*params*:
	#* survey_id: id of the survey to be obtained
	#
	#*retval*:
	#* a Survey object: when survey is successfully obtained
	#* ErrorEnum ::SURVEY_NOT_EXIST : when the survey does not exist
	#* ErrorEnum ::UNAUTHORIZED : when the survey does not belong to the current user
	def show
		@survey = Survey.find_by_id(params[:id])
		if @survey.nil?
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::SURVEY_NOT_EXIST) and return }
			end
		end
		respond_to do |format|
			format.json	{ render_json_auto(@survey.serialize) and return }
		end
	end

	def add_tag
		retval = @survey.add_tag(params[:tag])
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end

	def remove_tag
		retval = @survey.remove_tag(params[:tag])
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end

	def index
		if params[:stars] then
			survey_list = @current_user.surveys.stars
		else
			survey_list = @current_user.surveys.list(params[:status])
		end	
		
		paginated_surveys = auto_paginate survey_list

		# add answer_number
		data = paginated_surveys["data"].map do |e| 
			e.serialize_in_list_page
		end

		paginated_surveys["data"] = data

		render_json_auto paginated_surveys
	end

	def list_answered_surveys
		surveys_with_answer_status = Survey.list_answered_surveys(@current_user)
		paginated_surveys = auto_paginate surveys_with_answer_status
		render_json_auto(paginated_surveys)
	end

	def list_spreaded_surveys
		surveys_with_spreaded_number = Survey.list_spreaded_surveys(@current_user)
		paginated_surveys = auto_paginate surveys_with_spreaded_number
		render_json_auto(paginated_surveys)
	end

	def publish
		retval = @survey.publish(@current_user)
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end

	def update_deadline
		retval = @survey.update_deadline(params[:deadline])
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end

	def check_progress
		retval = @survey.check_progress(params[:detail])
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end
	
	def update_star
		retval = @survey.update_star(params[:is_star])
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end

	def search_title
		surveys = Survey.search_title(params[:query], @current_user)
		paginated_surveys = auto_paginate surveys
		render_json_auto(paginated_surveys)
	end

	def default_reward_scheme_id
		render_json_auto @survey.reward_schemes.where(:default => true).first.try(:_id) and return
	end
end
