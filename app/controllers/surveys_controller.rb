require 'array'
require 'error_enum'
require 'quill_common'
class SurveysController < ApplicationController
	before_filter :require_sign_in, :except => [:show, :estimate_answer_time, :list_surveys_in_community, :reward_info, :search_title]
	before_filter :check_survey_existence, :only => [:add_tag, :remove_tag, :update_deadline, :update_star]
	before_filter :check_normal_survey_existence, :except => [:new, :index, :list_surveys_in_community, :list_answered_surveys, :list_spreaded_surveys, :recover, :clear, :add_tag, :remove_tag, :show, :estimate_answer_time, :reward_info, :update_star, :search_title]
	before_filter :check_deleted_survey_existence, :only => [:recover, :clear]
	
	def check_survey_existence
		@survey = (@current_user.is_admin || @current_user.is_super_admin) ? Survey.find_by_id(params[:id]) : @current_user.surveys.find_by_id(params[:id])
		if @survey.nil?
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::SURVEY_NOT_EXIST) and return }
			end
		end
	end

	def check_normal_survey_existence
		@survey = (@current_user.is_admin || @current_user.is_super_admin) ? Survey.normal.find_by_id(params[:id]) : @current_user.surveys.normal.find_by_id(params[:id])
		if @survey.nil?
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::SURVEY_NOT_EXIST) and return }
			end
		end
	end

	def check_deleted_survey_existence
		@survey = (@current_user.is_admin || @current_user.is_super_admin) ? Survey.deleted.find_by_id(params[:id]) : @current_user.surveys.deleted.find_by_id(params[:id])
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
		if @current_user.is_admin || @current_user.is_super_admin
			survey.publish_status = QuillCommon::PublishStatusEnum::PUBLISHED
		else
			survey.style_setting["has_advertisement"] = false
		end
		survey.save
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
		@survey.close("", @current_user)
		retval = @survey.delete
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
		retval = @survey.recover
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
		retval = @survey.clear
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

	#*method*: put
	#
	#*url*: /surveys/:survey_id/add_tag
	#
	#*description*: add a tag to a survey
	#
	#*params*:
	#* survey_id: id of the survey
	#* tag: tag to be added
	#
	#*retval*:
	#* the survey object
	#* ErrorEnum ::SURVEY_NOT_EXIST : when the survey does not exist
	#* ErrorEnum ::TAG_EXIST : when the survey already has the tag
	def add_tag
		retval = @survey.add_tag(params[:tag])
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end

	#*method*: put
	#
	#*url*: /surveys/:survey_id/remove_tag
	#
	#*description*: remove a tag from a survey
	#
	#*params*:
	#* survey_id: id of the survey
	#* tags: tag to be removed
	#
	#*retval*:
	#* the survey object
	#* ErrorEnum ::SURVEY_NOT_EXIST : when the survey does not exist
	#* ErrorEnum ::UNAUTHORIZED : when the survey does not belong to the current user
	#* ErrorEnum ::TAG_NOT_EXIST : when the survey does not have the tag
	def remove_tag
		retval = @survey.remove_tag(params[:tag])
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end

	#*method*: post
	#
	#*url*: /surveys/list
	#
	#*description*: obtain a list of survey objects given a list tags
	#
	#*params*:
	#* tags: array of tags
	#* status: can be "all", "deleted", "normal"
	#* publish_status
	#
	#*retval*:
	#* a list Survey objects
	def index
		if params[:stars] then
			survey_list = @current_user.surveys.stars.desc(:created_at)
		else
			survey_list = @current_user.surveys.list(params[:status], params[:publish_status], params[:tags])
		end	
		# add answer_number
		survey_list.map do |e| 
			e['screened_answer_number']=e.answers.not_preview.screened.length
			e['finished_answer_number']=e.answers.not_preview.finished.length
		end
		paginated_surveys = auto_paginate survey_list
		render_json_auto(paginated_surveys)
	end

	def list_surveys_in_community
		surveys = Survey.list_surveys_in_community(params[:reward].to_i,
										params[:only_spreadable].to_s == "true",
										@current_user)
		paginated_surveys = auto_paginate surveys
		render_json_auto(paginated_surveys)
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

	#*method*: put
	#
	#*url*: /surveys/:survey_id/submit
	#
	#*description*: submit a survey to the administrator for reviewing
	#
	#*params*:
	#* survey_id: id of the suvey submitted
	#* message: the message that the user wants to give the administrator
	#
	#*retval*:
	#* true when the survey is successfully submitted
	#* ErrorEnum::SURVEY_NOT_EXIST
	#* ErrorEnum::WRONG_PUBLISH_STATUS
	def submit
		retval = @survey.submit(params[:message], @current_user)
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end

	#*method*: put
	#
	#*url*: /surveys/:survey_id/close
	#
	#*description*: close a suvey
	#
	#*params*:
	#* survey_id: id of the suvey to be closed
	#* message: the message that the user wants to give the administrator
	#
	#*retval*:
	#* true when the survey is successfully closed
	#* ErrorEnum::SURVEY_NOT_EXIST
	#* ErrorEnum::UNAUTHORIZED
	#* ErrorEnum::WRONG_PUBLISH_STATUS
	def close
		retval = @survey.close(params[:message], @current_user)
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end

	#*method*: put
	#
	#*url*: /surveys/:survey_id/update_deadline
	#
	#*description*: the owner of the survey updates the deadline of the survey
	#
	#*params*:
	#* survey_id: id of the suvey to be set
	#* deadline: deadline to be setted
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
	
	#*method*: POST
	#
	#*url*: /surveys/:survey_id/update_star
	#
	#*description*: set or remove one survey to a star
	#
	#*params*:
	#* survey_id: id of the suvey to be set
	#* is_star: bool. is star or not
	#
	#*retval*:
	# true or false
	def update_star
		retval = @survey.update_star(params[:is_star])
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end

	def estimate_answer_time
		survey = Survey.normal.find_by_id(params[:id])
		respond_to do |format|
			format.json	{ render_json_auto(survey.nil? ? ErrorEnum::SURVEY_NOT_EXIST : survey.estimate_answer_time) and return }
		end
	end

	def reward_info
		survey = Survey.normal.find_by_id(params[:id])
		respond_to do |format|
			format.json	{ render_json_auto(survey.nil? ? ErrorEnum::SURVEY_NOT_EXIST : survey.reward_info) and return }
		end
	end

	def search_title
		surveys = @current_user.surveys.search_title(params[:query])
		paginated_surveys = auto_paginate surveys
		render_json_auto(paginated_surveys)
	end
end
