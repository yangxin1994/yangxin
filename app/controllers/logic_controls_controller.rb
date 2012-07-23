# encoding: utf-8
require 'error_enum'
class LogicControlsController < ApplicationController
	before_filter :require_sign_in

	#*method*: get
	#
	#*url*: /surveys/:survey_id/quotas
	#
	#*description*: list all the quota rules of a survey
	#
	#*params*:
	#* survey_id: id of the survey
	#
	#*retval*:
	#* a hash of attributes that represent quotas
	#* ErrorEnum ::SURVEY_NOT_EXIST : when the survey does not exist
	#* ErrorEnum ::UNAUTHORIZED : when the survey does not belong to the current user
	def index
		survey = @current_user.surveys.normal.find_by_id(params[:survey_id])
		if survey.nil?
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::SURVEY_NOT_EXIST and return }
			end
		end		

		logic_control = survey.show_logic_control
		respond_to do |format|
			format.json	{ render :json => logic_control and return }
		end
	end

	#*method*: post
	#
	#*url*: /surveys/:survey_id/quotas
	#
	#*description*: create a new quota rule
	#
	#*params*:
	#* survey_id: id of the survey
	#* quota_rule: the rule to be created
	#
	#*retval*:
	#* the Quota object
	#* ErrorEnum ::SURVEY_NOT_EXIST : when the survey does not exist
	#* ErrorEnum ::UNAUTHORIZED : when the survey does not belong to the current user
	#* ErrorEnum ::WRONG_QUOTA_RULE_AMOUNT
	#* ErrorEnum ::WRONG_QUOTA_RULE_CONDITION_TYPE
	def create
		survey = @current_user.surveys.normal.find_by_id(params[:survey_id])
		if survey.nil?
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::SURVEY_NOT_EXIST and return }
			end
		end		

		logic_control = survey.add_logic_control_rule(params[:logic_control_rule])
		respond_to do |format|
			format.json	{ render :json => logic_control and return }
		end
	end

	#*method*: put
	#
	#*url*: /surveys/:survey_id/quotas/:quota_rule_index
	#
	#*description*: update a new quota rule
	#
	#*params*:
	#* survey_id: id of the survey
	#* quota_rule_index: index of the rule to be updated
	#* rule: the rule to be created
	#
	#*retval*:
	#* the Quota object
	#* ErrorEnum ::SURVEY_NOT_EXIST : when the survey does not exist
	#* ErrorEnum ::UNAUTHORIZED : when the survey does not belong to the current user
	#* ErrorEnum ::WRONG_QUOTA_RULE_AMOUNT
	#* ErrorEnum ::WRONG_QUOTA_RULE_CONDITION_TYPE
	def update
		survey = @current_user.surveys.normal.find_by_id(params[:survey_id])
		if survey.nil?
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::SURVEY_NOT_EXIST and return }
			end
		end		

		logic_control = survey.update_logic_control_rule(params[:id], params[:logic_control_rule])
		respond_to do |format|
			format.json	{ render :json => logic_control and return }
		end
	end

	#*method*: delete
	#
	#*url*: /surveys/:survey_id/quotas/:quota_rule_index
	#
	#*description*: delete a quota rule
	#
	#*params*:
	#* survey_id: id of the survey
	#* quota_rule_index: index of the rule to be deleted
	#
	#*retval*:
	#* the Quota object
	#* ErrorEnum ::SURVEY_NOT_EXIST : when the survey does not exist
	#* ErrorEnum ::UNAUTHORIZED : when the survey does not belong to the current user
	#* ErrorEnum ::QUOTA_RULE_NOT_EXIST
	def destroy
		survey = @current_user.surveys.normal.find_by_id(params[:survey_id])
		if survey.nil?
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::SURVEY_NOT_EXIST and return }
			end
		end		

		retval = survey.delete_logic_control_rule(params[:id])
		respond_to do |format|
			format.json	{ render :json => retval and return }
		end
	end
end
