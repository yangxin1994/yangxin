# encoding: utf-8
require 'error_enum'
class QuestionsController < ApplicationController
	before_filter :require_sign_in


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
	#* a Question object: when question is successfully created
	#* ErrorEnum ::Overflow: when the page index is greater than the page number
	#* ErrorEnum ::SurveyNotExist: when the survey does not exist
	#* ErrorEnum ::QuestionNotExist: when the question, after which the new one is created, does not exist
	#* ErrorEnum ::Unauthorized: when the survey does not belong to the current user
	def create
		retval = @current_user.create_question(params[:survey_id], params[:page_index].to_i, params[:question_id], params[:question_type])
		case retval
		when ErrorEnum::SurveyNotExist
			flash[:notice] = "该调查问卷不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::SurveyNotExist and return }
			end
		when ErrorEnum::QuestionNotExist
			flash[:notice] = "前一个问题不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::QuestionNotExist and return }
			end
		when ErrorEnum::Overflow
			flash[:notice] = "页码溢出"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::Overflow and return }
			end
		when ErrorEnum::Unauthorized
			flash[:notice] = "没有权限"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::Unauthorized and return }
			end
		else
			flash[:notice] = "成功创建新问题"
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
	#* ErrorEnum ::SurveyNotExist: when the survey does not exist
	#* ErrorEnum ::QuestionNotExist: when the question does not exist
	#* ErrorEnum ::Unauthorized: when the survey does not belong to the current user
	def update
		retval = @current_user.update_question(params[:survey_id], params[:question_id], params[:question])
		case retval
		when ErrorEnum::SurveyNotExist
			flash[:notice] = "调查问卷不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::SurveyNotExist and return }
			end
		when ErrorEnum::QuestionNotExist
			flash[:notice] = "问题不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::QuestionNotExist and return }
			end
		when ErrorEnum::Overflow
			flash[:notice] = "页码溢出"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::Overflow and return }
			end
		when ErrorEnum::Unauthorized
			flash[:notice] = "没有权限"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::Unauthorized and return }
			end
		else
			flash[:notice] = "成功更新问题"
			respond_to do |format|
				format.json	{ render :json => retval and return }
			end
		end
	end


	#*method*: post
	#
	#*url*: /surveys/:survey_id/questions/:question_id_1/:question_id_2/move
	#
	#*description*: move a question after another give question
	#
	#*params*:
	#* survey_id: id of the survey
	#* question_id_1: id of the question to be moved
	#* page_index: index of the page, where the question is moved to. Page index starts from 0
	#* question_id_2: id of the question, after which the above question is moved
	#
	#*retval*:
	#* 1: when question is successfully moved
	#* ErrorEnum ::SurveyNotExist: when the survey does not exist
	#* ErrorEnum ::QuestionNotExist: when the question does not exist
	#* ErrorEnum ::Overflow: when the page index is greater than the page number
	#* ErrorEnum ::Unauthorized: when the survey does not belong to the current user
	def move
		retval = @current_user.move_question(params[:survey_id], params[:question_id_1], params[:page_index].to_i, params[:question_id_2])
		case retval
		when ErrorEnum::SurveyNotExist
			flash[:notice] = "调查问卷不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::SurveyNotExist and return }
			end
		when ErrorEnum::QuestionNotExist
			flash[:notice] = "问题不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::QuestionNotExist and return }
			end
		when ErrorEnum::Overflow
			flash[:notice] = "页码溢出"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::Overflow and return }
			end
		when ErrorEnum::Unauthorized
			flash[:notice] = "没有权限"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::Unauthorized and return }
			end
		else
			flash[:notice] = "成功更新问题"
			respond_to do |format|
				format.json	{ render :json => 1 and return }
			end
		end
	end


	#*method*: get
	#
	#*url*: /surveys/:survey_id/questions/:question_id/clone
	#
	#*description*: clone a question and put the new question after the original one
	#
	#*params*:
	#* survey_id: id of the survey
	#* question_id_1: id of the question to be moved
	#* page_index: index of the page, where the question is moved to. Page index starts from 0
	#* question_id_2: id of the question, after which the above question is moved
	#
	#*retval*:
	#* : when question is successfully cloned
	#* ErrorEnum ::SurveyNotExist: when the survey does not exist
	#* ErrorEnum ::QuestionNotExist: when the question does not exist
	#* ErrorEnum ::Overflow: when the page index is greater than the page number
	#* ErrorEnum ::Unauthorized: when the survey does not belong to the current user
	def clone
		retval = @current_user.clone_question(params[:survey_id], params[:question_id_1], params[:page_index], params[:question_id_2])
		case retval
		when ErrorEnum::SurveyNotExist
			flash[:notice] = "调查问卷不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::SurveyNotExist and return }
			end
		when ErrorEnum::QuestionNotExist
			flash[:notice] = "问题不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::QuestionNotExist and return }
			end
		when ErrorEnum::Overflow
			flash[:notice] = "页码溢出"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::Overflow and return }
			end
		when ErrorEnum::Unauthorized
			flash[:notice] = "没有权限"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::Unauthorized and return }
			end
		else
			flash[:notice] = "成功获取问题"
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
	#* ErrorEnum ::SurveyNotExist: when the survey does not exist
	#* ErrorEnum ::QuestionNotExist: when the question does not exist
	#* ErrorEnum ::Unauthorized: when the survey does not belong to the current user
	def show
		retval = @current_user.get_question_object(params[:survey_id], params[:question_id])
		case retval
		when ErrorEnum::SurveyNotExist
			flash[:notice] = "调查问卷不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::SurveyNotExist and return }
			end
		when ErrorEnum::QuestionNotExist
			flash[:notice] = "问题不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::QuestionNotExist and return }
			end
		when ErrorEnum::Unauthorized
			flash[:notice] = "没有权限"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::Unauthorized and return }
			end
		else
			flash[:notice] = "成功获取问题"
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
	#* 1: when question is successfully deleted
	#* ErrorEnum ::SurveyNotExist: when the survey does not exist
	#* ErrorEnum ::QuestionNotExist: when the question does not exist
	#* ErrorEnum ::Unauthorized: when the survey does not belong to the current user
	def destroy
		retval = @current_user.delete_question(params[:survey_id], params[:question_id])
		case retval
		when ErrorEnum::SurveyNotExist
			flash[:notice] = "调查问卷不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::SurveyNotExist and return }
			end
		when ErrorEnum::QuestionNotExist
			flash[:notice] = "问题不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::QuestionNotExist and return }
			end
		when ErrorEnum::Unauthorized
			flash[:notice] = "没有权限"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::Unauthorized and return }
			end
		else
			flash[:notice] = "成功删除问题"
			respond_to do |format|
				format.json	{ render :json => 1 and return }
			end
		end
	end

end
