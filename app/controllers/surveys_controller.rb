# encoding: utf-8
require 'error_enum'
class SurveysController < ApplicationController
	before_filter :require_sign_in
	before_filter :check_survey_existence, :only => [:add_tag, :remove_tag]
	before_filter :check_normal_survey_existence, :except => [:new, :save_meta_data, :index, :recover, :clear, :add_tag, :remove_tag]
	before_filter :check_deleted_survey_existence, :only => [:recover, :clear]

	def check_survey_existence
		@survey = @current_user.surveys.find_by_id(params[:id])
		if @survey.nil?
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::SURVEY_NOT_EXIST and return }
			end
		end
	end

	def check_normal_survey_existence
		@survey = @current_user.surveys.normal.find_by_id(params[:id])
		if @survey.nil?
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::SURVEY_NOT_EXIST and return }
			end
		end
	end

	def check_deleted_survey_existence
		@survey = @current_user.surveys.deleted.find_by_id(params[:id])
		if @survey.nil?
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::SURVEY_NOT_EXIST and return }
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
		survey.save
		respond_to do |format|
			format.json	{ render :json => survey.to_json and return }
		end
	end

	#*method*: post
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
		survey = @current_user.surveys.normal.find_by_id(params[:id])
		if survey.nil?
			survey = Survey.normal.find_by_id(params[:id])
			if !survey.nil? && survey.user.nil?
				survey.user = @current_user
			else
				respond_to do |format|
					format.json	{ render :json => ErrorEnum::SURVEY_NOT_EXIST and return }
				end
			end
		end
		survey = survey.save_meta_data(params[:survey])
		respond_to do |format|
			format.json	{ render :json => survey.to_json and return }
		end
	end

	def show_style_setting
		style_setting = @survey.show_style_setting
		respond_to do |format|
			format.json	{ render :json => style_setting and return }
		end
	end

	def update_style_setting
		retval = @survey.update_style_setting(params[:style_setting])
		respond_to do |format|
			format.json	{ render :json => retval and return }
		end
	end

	def show_quality_control_setting
		style_setting = @survey.show_quality_control_setting
		respond_to do |format|
			format.json	{ render :json => style_setting and return }
		end
	end

	def update_quality_control_setting
		retval = @survey.update_quality_control_setting(params[:quality_control_setting])
		respond_to do |format|
			format.json	{ render :json => retval and return }
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
		retval = @survey.delete
		@survey.close("", @current_user)
		respond_to do |format|
			format.json	{ render :json => retval and return }
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
			format.json	{ render :json => retval and return }
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
			format.json	{ render :json => retval and return }
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
		new_survey = @survey.clone
		respond_to do |format|
			format.json	{ render :json => new_survey.to_json and return }
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
			format.json	{ render :json => @survey.to_json and return }
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
	#* ErrorEnum ::UNAUTHORIZED : when the survey does not belong to the current user
	#* ErrorEnum ::TAG_EXIST : when the survey already has the tag
	def add_tag
		retval = @survey.add_tag(params[:tag])
		respond_to do |format|
			format.json	{ render :json => retval and return }
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
			format.json	{ render :json => retval and return }
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
		survey_list = @current_user.surveys.list(params[:status], params[:public_status], params[:tags])
		respond_to do |format|
			format.json	{ render :json => survey_list.to_json and return }
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
			format.json	{ render :json => retval and return }
		end
	end

	#*method*: get
	#
	#*url*: /surveys/:survey_id/reject
	#
	#*description*: reject a survey to be published
	#
	#*params*:
	#* survey_id: id of the suvey rejected
	#* message: the message that the user wants to give the administrator
	#
	#*retval*:
	#* true when the survey is successfully rejected
	#* ErrorEnum::SURVEY_NOT_EXIST
	#* ErrorEnum::UNAUTHORIZED
	#* ErrorEnum::WRONG_PUBLISH_STATUS
	def reject
		retval = @survey.reject(params[:message], @current_user)
		respond_to do |format|
			format.json	{ render :json => retval and return }
		end
	end

	#*method*: get
	#
	#*url*: /surveys/:survey_id/publish
	#
	#*description*: publish
	#
	#*params*:
	#* survey_id: id of the suvey published
	#* message: the message that the user wants to give the administrator
	#
	#*retval*:
	#* true when the survey is successfully published
	#* ErrorEnum::SURVEY_NOT_EXIST
	#* ErrorEnum::UNAUTHORIZED
	#* ErrorEnum::WRONG_PUBLISH_STATUS
	def publish
		retval = @survey.publish(params[:message], @current_user)
		respond_to do |format|
			format.json	{ render :json => retval and return }
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
			format.json	{ render :json => retval and return }
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
			format.json	{ render :json => retval and return }
		end
	end
end
