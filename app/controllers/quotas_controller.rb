# encoding: utf-8
require 'error_enum'
class QuotasController < ApplicationController
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
		retval = @current_user.show_quota(params[:survey_id])
		case retval
		when ErrorEnum::SURVEY_NOT_EXIST
			flash[:notice] = "该调查问卷不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::SURVEY_NOT_EXIST and return }
			end
		when ErrorEnum::UNAUTHORIZED
			flash[:notice] = "没有权限"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::UNAUTHORIZED and return }
			end
		else
			flash[:notice] = "成功获取问卷配额"
			respond_to do |format|
				format.json	{ render :json => retval and return }
			end
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
		retval = @current_user.add_quota_rule(params[:survey_id], params[:quota_rule])
		case retval
		when ErrorEnum::SURVEY_NOT_EXIST
			flash[:notice] = "该调查问卷不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::SURVEY_NOT_EXIST and return }
			end
		when ErrorEnum::UNAUTHORIZED
			flash[:notice] = "没有权限"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::UNAUTHORIZED and return }
			end
		when ErrorEnum::WRONG_QUOTA_RULE_AMOUNT
			flash[:notice] = "配额量错误"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::WRONG_QUOTA_RULE_AMOUNT and return }
			end
		when ErrorEnum::WRONG_QUOTA_RULE_CONDITION_TYPE
			flash[:notice] = "配额属性名称错误"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::WRONG_QUOTA_RULE_CONDITION_TYPE and return }
			end
		else
			flash[:notice] = "成功添加配额规则"
			respond_to do |format|
				format.json	{ render :json => quota and return }
			end
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
		retval = @current_user.update_quota_rule(params[:survey_id], params[:id], params[:rule])
		case retval
		when ErrorEnum::SURVEY_NOT_EXIST
			flash[:notice] = "该调查问卷不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::SURVEY_NOT_EXIST and return }
			end
		when ErrorEnum::UNAUTHORIZED
			flash[:notice] = "没有权限"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::UNAUTHORIZED and return }
			end
		when ErrorEnum::WRONG_QUOTA_RULE_AMOUNT
			flash[:notice] = "配额量错误"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::WRONG_QUOTA_RULE_AMOUNT and return }
			end
		when ErrorEnum::WRONG_QUOTA_RULE_CONDITION_TYPE
			flash[:notice] = "配额属性名称错误"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::WRONG_QUOTA_RULE_CONDITION_TYPE and return }
			end
		else
			flash[:notice] = "成功更新配额规则"
			respond_to do |format|
				format.json	{ render :json => quota and return }
			end
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
		retval = @current_user.delete_quota_rule(params[:survey_id], params[:id].to_i)
		case retval
		when ErrorEnum::SURVEY_NOT_EXIST
			flash[:notice] = "该调查问卷不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::SURVEY_NOT_EXIST and return }
			end
		when ErrorEnum::UNAUTHORIZED
			flash[:notice] = "没有权限"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::UNAUTHORIZED and return }
			end
		else
			flash[:notice] = "成功删除配额规则"
			respond_to do |format|
				format.json	{ render :json => retval and return }
			end
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
	#* ErrorEnum ::UNAUTHORIZED : when the survey does not belong to the current user
	def set_exclusive
		retval = @current_user.set_exclusive(params[:survey_id], !!params[:is_exclusive])
		case retval
		when ErrorEnum::SURVEY_NOT_EXIST
			flash[:notice] = "该调查问卷不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::SURVEY_NOT_EXIST and return }
			end
		when ErrorEnum::UNAUTHORIZED
			flash[:notice] = "没有权限"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::UNAUTHORIZED and return }
			end
		else
			flash[:notice] = "成功设置"
			respond_to do |format|
				format.json	{ render :json => retval and return }
			end
		end
	end
end
