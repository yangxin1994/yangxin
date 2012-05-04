# encoding: utf-8
require 'error_enum'
class SurveysController < ApplicationController
	before_filter :require_sign_in

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
	def new
		@survey_object = Survey.new.set_default_meta_data(@current_user.email).serialize
		respond_to do |format|
			format.json	{ render :json => @survey_object and return }
		end
	end

	#*method*: post
	#
	#*url*: /surveys/save_meta_data
	#
	#*description*: save meta data of a survey
	#
	#*params*:
	#* survey: a Survey object
	#
	#*retval*:
	#* 1: when meta data is successfully saved.
	#* ErrorEnum ::SURVEY_NOT_EXIST : when the survey does not exist
	#* ErrorEnum ::UNAUTHORIZED : when the survey does not belong to the current user
	def save_meta_data
		retval = @current_user.save_meta_data(params[:survey])
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
			flash[:notice] = "保存成功"
			respond_to do |format|
				format.json	{ render :json => 1 and return }
			end
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
	#* 1: when survey is successfully deleted.
	#* ErrorEnum ::SURVEY_NOT_EXIST : when the survey does not exist
	#* ErrorEnum ::UNAUTHORIZED : when the survey does not belong to the current user
	def destroy
		retval = @current_user.destroy_survey(params[:id])
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
			flash[:notice] = "调查问卷已成功删除"
			respond_to do |format|
				format.json	{ render :json => 1 and return }
			end
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
		retval = @current_user.clone_survey(params[:id])
		case retval
		when ErrorEnum::SURVEY_NOT_EXIST
			flash[:notice] = "该调查问卷不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::SURVEY_NOT_EXISTand return }
			end
		when ErrorEnum::UNAUTHORIZED
			flash[:notice] = "没有权限"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::UNAUTHORIZED and return }
			end
		else
			flash[:notice] = "调查问卷已成功复制"
			respond_to do |format|
				format.json	{ render :json => retval and return }
			end
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
		retval = @current_user.get_survey_object(params[:id])
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
			respond_to do |format|
				format.json	{ render :json => retval  and return }
			end
		end
	end

end
