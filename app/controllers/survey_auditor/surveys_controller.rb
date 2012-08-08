# encoding: utf-8
require 'error_enum'
class SurveyAuditor::SurveysController < SurveyAuditor::ApplicationController

	before_filter :check_normal_survey_existence, :except => [:index]
	
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

	#*method*: post
	#
	#*url*: /surveys/list
	#
	#*description*: obtain the list of survey objects waiting for reviewing
	#
	#*params*:
	#
	#*retval*:
	#* a list Survey objects
	def index
		# first parameter is survey status (0 for normal surveys)
		# second parameter is survey publish status (2 for under review surveys)
		# third parameter are tags
		survey_list = Survey.normal.list("normal", 2, nil)
		respond_to do |format|
			format.json	{ render :json => survey_list.to_json and return }
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
