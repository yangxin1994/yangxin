# encoding: utf-8
require 'error_enum'
class QualityControlQuestionsController < ApplicationController
	before_filter :require_admin

	#*method*: post
	#
	#*url*: /quality_control_questions
	#
	#*description*: create a new quality control question
	#
	#*params*:
	#* quality_control_type: 0 for objective quality control questins, 1 for matching quality control questions(integer)
	#* question_type: type of the question, can be either ChoiceQuestion, TextBlankQuestion, or NumberBlankQuestion(string)
	#* question_number: for matching questions, the number of the questinos.
	#
	#*retval*:
	#* [a Question object, an QualityControlQuestionAnswer object]: when question control type is 0 (objective quality control question)
	#* [a Question object, a Question object, an QualityControlQuestionAnswer object]: when question control type is 1 (matching quality control questions)
	#* ErrorEnum ::UNAUTHORIZED
	#* ErrorEnum ::WRONG_QUALITY_CONTROL_TYPE
	#* ErrorEnum ::WRONG_QUESTION_TYPE
	def create
		retval = @current_user.create_quality_control_question(params[:quality_control_type], params[:question_type], params[:question_number])
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

	#*method*: get
	#
	#*url*: /quality_control_questions
	#
	#*description*: list quality control questions
	#
	#*params*:
	#* quality_control_type: 0 for objective quality control questins, 1 for matching quality control questions(integer)
	#
	#*retval*:
	#* [a Question object, ..., a Question object]: when question control type is 0 (objective quality control question)
	#* [a group of Question objects, ..., a group of Question objects]: when question control type is 1 (matching quality control questions)
	#* ErrorEnum ::UNAUTHORIZED
	#* ErrorEnum ::WRONG_QUALITY_CONTROL_TYPE
	def index
		retval = @current_user.list_quality_control_questions(params[:quality_control_type])
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
	#*url*: /quality_control_questions/:question_id
	#
	#*description*: update quality control questions
	#
	#*params*:
	#* question_id: id of the question to be updated(in url)
	#* question: the object to be updated
	#
	#*retval*:
	#* question object : when successfully updated
	#* ErrorEnum ::UNAUTHORIZED
	#* ErrorEnum ::QUESTION_NOT_EXIST
	#* ErrorEnum ::WRONG_DATA_TYPE
	def update
		retval = @current_user.update_quality_control_question(params[:id], params[:question])
		case retval
		when ErrorEnum::UNAUTHORIZED
			flash[:notice] = "没有权限"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::UNAUTHORIZED and return }
			end
		when ErrorEnum::QUESTION_NOT_EXIST
			flash[:notice] = "问题不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::QUESTION_NOT_EXIST and return }
			end
		when ErrorEnum::WRONG_DATA_TYPE
			flash[:notice] = "数据类型错误"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::WRONG_DATA_TYPE and return }
			end
		else
			flash[:notice] = "成功更新质量控制问题"
			respond_to do |format|
				format.json	{ render :json => retval and return }
			end
		end
	end

	#*method*: put
	#
	#*url*: /quality_control_questions/update_quality_control_answer
	#
	#*description*: update quality control questions answers
	#
	#*params*:
	#* quality_control_type: 0 for objective quality control questins, 1 for matching quality control questions(integer)
	#* question_type: can be ChoiceQuestion, TextBlankQuestion, or NumberBlankQuestion
	#* question_id_ary: array of question ids
	#* answer: answer to be updated
	#
	#*retval*:
	#* the answer object
	#* ErrorEnum ::UNAUTHORIZED
	#* ErrorEnum ::WRONG_QUALITY_CONTROL_TYPE
	def update_quality_control_answer
		retval = @current_user.update_quality_control_answer(params[:answer])
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
			flash[:notice] = "成功更新质量控制答案"
			respond_to do |format|
				format.json	{ render :json => retval and return }
			end
		end
	end

	#*method*: get
	#
	#*url*: /quality_control_question/:question_id
	#
	#*description*: get a Question object (for objective question), or a group of Question objects (for matching questions)
	#
	#*params*:
	#* question_id: id of the question to be obtained
	#
	#*retval*:
	#* a Question object: when it is an objective question
	#* a group Question objects: when they are matching questions
	#* ErrorEnum ::QUESTION_NOT_EXIST: when the question does not exist
	#* ErrorEnum ::UNAUTHORIZED: when the survey does not belong to the current user
	#* ErrorEnum ::WRONG_QUALITY_CONTROL_TYPE
	def show
		retval = @current_user.show_quality_control_question(params[:id])
		case retval
		when ErrorEnum::UNAUTHORIZED
			flash[:notice] = "没有权限"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::UNAUTHORIZED and return }
			end
		when ErrorEnum::QUESTION_NOT_EXIST
			flash[:notice] = "质量控制题不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::QUESTION_NOT_EXIST and return }
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
