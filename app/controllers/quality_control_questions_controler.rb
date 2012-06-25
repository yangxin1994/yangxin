# encoding: utf-8
require 'error_enum'
class QualityControlQuestionsController < ApplicationController
	before_filter :require_admin

	#*method*: post
	#
	#*url*: /surveys/:survey_id/questions
	#
	#*description*: create a new question in the given page after the given question with given question type
	#
	#*params*:
	#* survey_id: id of the survey, in url
	#* page_index: index of the page, in which the new question is created. Page index starts from 0
	#* question_id: id of the question, after which the new question is created. if is set as -1, the new question will be created at the last of the page
	#* question_type: type of the question
	#
	#*retval*:
	#* a QualityControlQuestion object: when question is successfully created
	#* ErrorEnum ::UNAUTHORIZED: when the survey does not belong to the current user
	def create
		retval = @current_user.create_quality_control_question(params[:quality_control_type], params[:question_type])
		case retval
		when ErrorEnum::UNAUTHORIZED
			flash[:notice] = "没有权限"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::UNAUTHORIZED and return }
			end
		when ErrorEnum::WRONG_QUESTION_TYPE
			flash[:notice] = "错误的题目类型"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::WRONG_QUESTION_TYPE and return }
			end
		when ErrorEnum::WRONG_QUALITY_CONTROL_TYPE
			flash[:notice] = "错误的质量控制类型"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::WRONG_QUALITY_CONTROL_TYPE and return }
			end
		else
			flash[:notice] = "成功创建新质量控制问题"
			respond_to do |format|
				format.json	{ render :json => retval and return }
			end
		end
	end

	def index
		retval = @current_user.list_quality_control_questions(params[:question_type])
		case retval
		when ErrorEnum::UNAUTHORIZED
			flash[:notice] = "没有权限"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::UNAUTHORIZED and return }
			end
		when ErrorEnum::WRONG_QUALITY_CONTROL_TYPE
			flash[:notice] = "错误的质量控制题类型"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::WRONG_QUALITY_CONTROL_TYPE and return }
			end
		else
			flash[:notice] = "成功创建新质量控制问题"
			respond_to do |format|
				format.json	{ render :json => retval and return }
			end
		end
	end

	#*method*: put
	#
	#*url*: /surveys/:survey_id/questions/:question_id
	#
	#*description*: update a specific question
	#
	#*params*:
	#* survey_id: id of the survey
	#* question_id: id of the question to be updated
	#* question: the question object to be updated
	#
	#*retval*:
	#* question object: when question is successfully updated
	def update
		retval = @current_user.update_quality_control_question(params[:id], params[:question_obj])
		case retval
		when ErrorEnum::UNAUTHORIZED
			flash[:notice] = "没有权限"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::UNAUTHORIZED and return }
			end
		when ErrorEnum::WRONG_QUALITY_CONTROL_TYPE
			flash[:notice] = "错误的质量控制题类型"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::WRONG_QUALITY_CONTROL_TYPE and return }
			end
		when ErrorEnum::WRONG_QUALITY_CONTROL_QUESTION_ANSWER
			flash[:notice] = "质量控制题答案格式错误"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::WRONG_QUALITY_CONTROL_QUESTION_ANSWER and return }
			end
		else
			flash[:notice] = "成功更新质量控制问题"
			respond_to do |format|
				format.json	{ render :json => retval and return }
			end
		end
	end


	#*method*: get
	#
	#*url*: /surveys/:survey_id/questions/:question_id
	#
	#*description*: get a Question object
	#
	#*params*:
	#* survey_id: id of the survey
	#* question_id: id of the question to be obtained
	#
	#*retval*:
	#* an Question object: when question is successfully obtained
	#* ErrorEnum ::SURVEY_NOT_EXIST: when the survey does not exist
	#* ErrorEnum ::QUESTION_NOT_EXIST: when the question does not exist
	#* ErrorEnum ::UNAUTHORIZED: when the survey does not belong to the current user
	def show
		retval = @current_user.show_quality_control_question(params[:id])
		case retval
		when ErrorEnum::UNAUTHORIZED
			flash[:notice] = "没有权限"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::UNAUTHORIZED and return }
			end
		when ErrorEnum::QUALITY_CONTROL_QUESTION_NOT_EXIST
			flash[:notice] = "质量控制题不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::QUALITY_CONTROL_QUESTION_NOT_EXIST and return }
			end
		when ErrorEnum::WRONG_QUALITY_CONTROL_TYPE
			flash[:notice] = "错误的质量控制题类型"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::WRONG_QUALITY_CONTROL_TYPE and return }
			end
		else
			flash[:notice] = "成功获取质量控制问题"
			respond_to do |format|
				format.json	{ render :json => retval and return }
			end
		end
	end

	#*method*: delete
	#
	#*url*: /surveys/:survey_id/questions/:question_id
	#
	#*description*: delete a Question
	#
	#*params*:
	#* survey_id: id of the survey
	#* question_id: id of the question to be deleted
	#
	#*retval*:
	#* true: when question is successfully deleted
	#* ErrorEnum ::SURVEY_NOT_EXIST: when the survey does not exist
	#* ErrorEnum ::QUESTION_NOT_EXIST: when the question does not exist
	#* ErrorEnum ::UNAUTHORIZED: when the survey does not belong to the current user
	def destroy
		retval = @current_user.delete_quality_control_question(params[:id])
		case retval
		when ErrorEnum::UNAUTHORIZED
			flash[:notice] = "没有权限"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::UNAUTHORIZED and return }
			end
		else
			flash[:notice] = "成功删除问题"
			respond_to do |format|
				format.json	{ render :json => true and return }
			end
		end
	end
end
