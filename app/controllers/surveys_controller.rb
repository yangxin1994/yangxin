# encoding: utf-8
require 'array'
require 'error_enum'
class SurveysController < ApplicationController
	before_filter :require_sign_in
	before_filter :check_survey_existence, :only => [:add_tag, :remove_tag, :show, :update_deadline]
	before_filter :check_normal_survey_existence, :except => [:new, :index, :recover, :clear, :add_tag, :remove_tag, :show]
	before_filter :check_deleted_survey_existence, :only => [:recover, :clear]
	#TODO 无法测试
	def export_spss
		@survey = Survey.find_by_id(params[:id])

	end
	
	def export_csv
		@survey = Survey.find_by_id(params[:id])
		unless @survey.nil?
			send_data @survey.export_csv, :file_name => "#{@survey.title}.csv"
		end
	end

	def check_survey_existence
		@survey = @current_user.is_admin ? Survey.find_by_id(params[:id]) : @current_user.surveys.find_by_id(params[:id])
		if @survey.nil?
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::SURVEY_NOT_EXIST) and return }
			end
		end
	end

	def check_normal_survey_existence
		@survey = @current_user.is_admin ? Survey.normal.find_by_id(params[:id]) : @current_user.surveys.normal.find_by_id(params[:id])
		if @survey.nil?
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::SURVEY_NOT_EXIST) and return }
			end
		end
	end

	def check_deleted_survey_existence
		@survey = @current_user.is_admin ? Survey.deleted.find_by_id(params[:id]) : @current_user.surveys.deleted.find_by_id(params[:id])
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
		survey = Survey.find_new_by_user(@current_user)
		if survey.nil?
			survey = Survey.create
			survey.alt_new_survey = false
			@current_user.surveys << survey
		end
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

	def set_random_quality_control_questions
		retval = @survey.set_random_quality_control_questions(params[:random_quality_control_questions])
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end

	def get_random_quality_control_questions
		retval = @survey.get_random_quality_control_questions
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
		new_survey = @survey.clone_survey(params[:title])
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

		if params[:stars].nil? then
			survey_list = @current_user.surveys.list(params[:status], params[:publish_status], params[:tags])

			survey_list = slice((survey_list || []), params[:page], params[:per_page])

			respond_to do |format|
				format.json	{ render_json_auto(survey_list.serialize) and return }
			end
		else
			params[:page] ||= 1
			params[:per_page] ||= 10
			survey_list = @current_user.surveys.stars.page(params[:page]).per(params[:per_page])
			respond_to do |format|
				format.json	{ render_json_auto(survey_list) and return }
			end
		end
	end

	#*method*: get
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

	#*method*: get
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

	#*method*: get
	#
	#*url*: /surveys/:survey_id/pause
	#
	#*description*: the owner of the survey pause the survey
	#
	#*params*:
	#* survey_id: id of the suvey to be set
	#* message: the message that the administrator wants to give the user
	#
	#*retval*:
	#* true when the survey is successfully paused
	#* ErrorEnum::SURVEY_NOT_EXIST
	#* ErrorEnum::UNAUTHORIZED
	#* ErrorEnum::WRONG_PUBLISH_STATUS
	def pause
		retval = @survey.pause(params[:message], @current_user)
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end

	#*method*: POST
	#
	#*url*: /surveys/:survey_id/update_deadline
	#
	#*description*: the owner of the survey pause the survey
	#
	#*params*:
	#* survey_id: id of the suvey to be set
	def update_deadline
		retval = @survey.update_deadline(params[:deadline])
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end

	def check_progress
		retval = @survey.check_progress(params[:deadline])
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
	#
	#*retval*:
	# true or false
	def update_star
		retval = @survey.update_star
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end
end
