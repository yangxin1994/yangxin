require 'error_enum'
class QuotasController < ApplicationController
	before_filter :require_sign_in, :check_normal_survey_existence

	def check_normal_survey_existence
		@survey = @current_user.is_admin? ? Survey.normal.find_by_id(params[:survey_id]) : @current_user.surveys.normal.find_by_id(params[:survey_id])
		if @survey.nil?
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::SURVEY_NOT_EXIST) and return }
			end
		end
	end

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
	#* a hash of attributes that regift quotas
	#* ErrorEnum ::SURVEY_NOT_EXIST : when the survey does not exist
	def index
		quota = @survey.show_quota
		respond_to do |format|
			format.json	{ render_json_auto(quota) and return }
		end
	end

	#*method*: get
	#
	#*url*: /surveys/:survey_id/quotas/:quota_rule_index
	#
	#*description*: show a quota rule
	#
	#*params*:
	#* survey_id: id of the survey
	#* quota_rule_index: index of the quota rule
	#
	#*retval*:
	#* a hash of attributes that regift quotas
	#* ErrorEnum ::SURVEY_NOT_EXIST : when the survey does not exist
	def show
		quota_rule = @survey.show_quota_rule(params[:id].to_i)
		respond_to do |format|
			format.json	{ render_json_auto(quota_rule) and return }
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
	#* ErrorEnum ::WRONG_QUOTA_RULE_AMOUNT
	#* ErrorEnum ::WRONG_QUOTA_RULE_CONDITION_TYPE
	def create
		quota = @survey.add_quota_rule(params[:quota_rule])
		respond_to do |format|
			format.json	{ render_json_auto(quota) and return }
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
	#* ErrorEnum ::WRONG_QUOTA_RULE_AMOUNT
	#* ErrorEnum ::WRONG_QUOTA_RULE_CONDITION_TYPE
	#* ErrorEnum ::QUOTA_RULE_NOT_EXIST
	def update
		quota = @survey.update_quota_rule(params[:id].to_i, params[:quota_rule])
		respond_to do |format|
			format.json	{ render_json_auto(quota) and return }
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
	#* true : when successfully removed
	#* ErrorEnum ::SURVEY_NOT_EXIST : when the survey does not exist
	#* ErrorEnum ::QUOTA_RULE_NOT_EXIST
	def destroy
		retval = @survey.delete_quota_rule(params[:id].to_i)
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end

	#*method*: post
	#
	#*url*: /surveys/:survey_id/quotas/set_exclusive
	#
	#*description*: set the "is_exclusive" attribute of the quota
	#
	#*params*:
	#* survey_id: id of the survey
	#* is_exclusive: true or false
	#
	#*retval*:
	#* the Quota object
	#* ErrorEnum ::SURVEY_NOT_EXIST : when the survey does not exist
	def set_exclusive
		retval = @survey.set_exclusive(params[:is_exclusive].to_s == "true")
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end

	#*method*: get
	#
	#*url*: /surveys/:survey_id/quotas/get_exclusive
	#
	#*description*: get the "is_exclusive" attribute of the quota
	#
	#*params*:
	#* survey_id: id of the survey
	#
	#*retval*:
	#* the Quota object
	#* ErrorEnum ::SURVEY_NOT_EXIST : when the survey does not exist
	def get_exclusive
		retval = @survey.get_exclusive
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end

	#*method*: post
	#
	#*url*: /surveys/:survey_id/quotas/refresh
	#
	#*description*: refresh quotas stat
	#
	#*params*:
	#* survey_id: id of the survey
	#
	#*retval*:
	#* the Quota stat object
	#* ErrorEnum ::SURVEY_NOT_EXIST : when the survey does not exist
	def refresh
		retval = @survey.refresh_quota_stats
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end
end
