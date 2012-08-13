# encoding: utf-8
require 'error_enum'
class LogicControlsController < ApplicationController
	before_filter :require_sign_in, :check_normal_survey_existence

	def check_normal_survey_existence
		@survey = @current_user.surveys.normal.find_by_id(params[:survey_id])
		if @survey.nil?
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::SURVEY_NOT_EXIST and return }
			end
		end
	end

	#*method*: get
	#
	#*url*: /surveys/:survey_id/logic_controls
	#
	#*description*: list all the logic control rules of a survey
	#
	#*params*:
	#* survey_id: id of the survey
	#
	#*retval*:
	#* a array of logic control rules
	#* ErrorEnum ::SURVEY_NOT_EXIST : when the survey does not exist
	def index
		logic_control = @survey.show_logic_control
		respond_to do |format|
			format.json	{ render :json => logic_control and return }
		end
	end

	#*method*: get
	#
	#*url*: /surveys/:survey_id/logic_controls/:logic_control_rule_index
	#
	#*description*: show one logic control rule of a survey
	#
	#*params*:
	#* survey_id: id of the survey
	#* logic_control_rule_index: index of the logic control rule
	#
	#*retval*:
	#* a hash of attributes that represent the logic control rule
	#* ErrorEnum ::SURVEY_NOT_EXIST : when the survey does not exist
	#* ErrorEnum ::LOGIC_CONTROL_RULE_NOT_EXIST : when the survey does not exist
	def show
		logic_control_rule = @survey.show_logic_control_rule(params[:id].to_i)
		respond_to do |format|
			format.json	{ render :json => logic_control_rule and return }
		end
	end

	#*method*: post
	#
	#*url*: /surveys/:survey_id/logic_controls
	#
	#*description*: create a new logic control rule
	#
	#*params*:
	#* survey_id: id of the survey
	#* logic_control_rule: the rule to be created
	#
	#*retval*:
	#* the logic control object
	#* ErrorEnum ::SURVEY_NOT_EXIST : when the survey does not exist
	def create
		logic_control = @survey.add_logic_control_rule(params[:logic_control_rule])
		respond_to do |format|
			format.json	{ render :json => logic_control and return }
		end
	end

	#*method*: put
	#
	#*url*: /surveys/:survey_id/logic_controls/:logic_control_rule_index
	#
	#*description*: update a new logic control rule
	#
	#*params*:
	#* survey_id: id of the survey
	#* logic_control_rule_index: index of the rule to be updated
	#* rule: the rule to be created
	#
	#*retval*:
	#* the logic control object
	#* ErrorEnum ::SURVEY_NOT_EXIST : when the survey does not exist
	def update
		logic_control = @survey.update_logic_control_rule(params[:id].to_i, params[:logic_control_rule])
		respond_to do |format|
			format.json	{ render :json => logic_control and return }
		end
	end

	#*method*: delete
	#
	#*url*: /surveys/:survey_id/logic_controls/:logic_control_rule_index
	#
	#*description*: delete a logic control rule
	#
	#*params*:
	#* survey_id: id of the survey
	#* logic_control_rule_index: index of the rule to be deleted
	#
	#*retval*:
	#* the logic control object
	#* ErrorEnum ::SURVEY_NOT_EXIST : when the survey does not exist
	def destroy
		retval = @survey.delete_logic_control_rule(params[:id].to_i)
		respond_to do |format|
			format.json	{ render :json => retval and return }
		end
	end
end
