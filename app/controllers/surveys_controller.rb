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
	#* ErrorEnum::EMAIL_NOT_EXIST
	def new
		retval = Survey.new.set_default_meta_data(@current_user.email)
		case retval
		when ErrorEnum::EMAIL_NOT_EXIST
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::EMAIL_NOT_EXIST and return }
			end
		else
			respond_to do |format|
				format.json	{ render :json => retval and return }
			end
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
	#* the Survey object: when meta data is successfully saved.
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
				format.json	{ render :json => retval and return }
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
	#* true: when survey is successfully deleted.
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
				format.json	{ render :json => true and return }
			end
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
		retval = @current_user.recover_survey(params[:id])
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
			flash[:notice] = "调查问卷已成功恢复"
			respond_to do |format|
				format.json	{ render :json => true and return }
			end
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
		retval = @current_user.clear_survey(params[:id])
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
			flash[:notice] = "调查问卷已成功彻底删除"
			respond_to do |format|
				format.json	{ render :json => true and return }
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
				format.json	{ render :json => ErrorEnum::SURVEY_NOT_EXISTand and return }
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
				format.json	{ render :json => retval and return }
			end
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
		retval = @current_user.add_survey_tag(params[:id], params[:tag])
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
		when ErrorEnum::TAG_EXIST
			flash[:notice] = "标签已经存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::TAG_EXIST and return }
			end
		else
			flash[:notice] = "已成功添加标签"
			respond_to do |format|
				format.json	{ render :json => retval and return }
			end
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
		retval = @current_user.remove_survey_tag(params[:id], params[:tag])
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
		when ErrorEnum::TAG_NOT_EXIST
			flash[:notice] = "标签不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::TAG_NOT_EXIST and return }
			end
		else
			flash[:notice] = "已成功删除标签"
			respond_to do |format|
				format.json	{ render :json => retval and return }
			end
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
	#
	#*retval*:
	#* a list Survey objects
	def list
		retval = @current_user.get_survey_object_list(params[:tags])
		respond_to do |format|
			format.json	{ render :json => retval and return }
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
	#* ErrorEnum::UNAUTHORIZED
	#* ErrorEnum::WRONG_PUBLISH_STATUS
	def submit
		retval = @current_user.submit_survey(params[:id], params[:message])
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
		when ErrorEnum::WRONG_PUBLISH_STATUS
			flash[:notice] = "不能提交问卷"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::WRONG_PUBLISH_STATUS and return }
			end
		else
			flash[:notice] = "已成功提交问卷"
			respond_to do |format|
				format.json	{ render :json => true and return }
			end
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
		retval = @current_user.reject_survey(params[:id], params[:message])
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
		when ErrorEnum::WRONG_PUBLISH_STATUS
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::WRONG_PUBLISH_STATUS and return }
			end
		else
			flash[:notice] = "已成功拒绝问卷"
			respond_to do |format|
				format.json	{ render :json => true and return }
			end
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
		retval = @current_user.publish_survey(params[:id], params[:message])
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
		when ErrorEnum::WRONG_PUBLISH_STATUS
			flash[:notice] = "不能提交问卷"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::WRONG_PUBLISH_STATUS and return }
			end
		else
			flash[:notice] = "已成功发布问卷"
			respond_to do |format|
				format.json	{ render :json => true and return }
			end
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
		retval = @current_user.close_survey(params[:id], params[:message])
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
			flash[:notice] = "已成功发布问卷"
			respond_to do |format|
				format.json	{ render :json => true and return }
			end
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
		retval = @current_user.pause_survey(params[:id], params[:message])
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
			flash[:notice] = "已成功发布问卷"
			respond_to do |format|
				format.json	{ render :json => true and return }
			end
		end
	end
end
