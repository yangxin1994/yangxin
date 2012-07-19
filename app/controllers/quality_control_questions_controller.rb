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
	#* a Question object: when question is successfully created
	#* ErrorEnum ::OVERFLOW: when the page index is greater than the page number
	#* ErrorEnum ::SURVEY_NOT_EXIST: when the survey does not exist
	#* ErrorEnum ::QUESTION_NOT_EXIST: when the question, after which the new one is created, does not exist
	#* ErrorEnum ::UNAUTHORIZED: when the survey does not belong to the current user
	def create
		quality_control_question = QualityControlQuestion.create_quality_control_question(params[:quality_control_type].to_i, params[:question_type].to_i, params[:question_number].to_i, @current_user)
		respond_to do |format|
			format.json	{ render :json => quality_control_question and return }
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
	#* ErrorEnum ::SURVEY_NOT_EXIST: when the survey does not exist
	#* ErrorEnum ::QUESTION_NOT_EXIST: when the question does not exist
	#* ErrorEnum ::UNAUTHORIZED: when the survey does not belong to the current user
	#* ErrorEnum ::WRONG_DATA_TYPE: when the data type specified in a blank question is wrong
	def update
		question = QualityControlQuestion.find_by_id(params[:id])
		if survey.nil?
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::QUALITY_CONTROL_QUESTION_NOT_EXIST and return }
			end
		end

		question = question.update_question(params[:question], @current_user)
		respond_to do |format|
			format.json	{ render :json => question and return }
		end
	end

	def update_answer
		retval = QualityControlQuestionAnswer.update_answers(params[:id], params[:quality_control_type], params[:answer], @current_user)
		respond_to do |format|
			format.json	{ render :json => retval and return }
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
		question = QualityControlQuestion.find_by_id(params[:id])
		if survey.nil?
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::QUALITY_CONTROL_QUESTION_NOT_EXIST and return }
			end
		end

		question = question.show_quality_control_question(@current_user)
		respond_to do |format|
			format.json	{ render :json => question and return }
		end
	end

	def index
		questions = QualityControlQuestion.list_quality_control_question(params[:quality_control_type], @current_user)
		respond_to do |format|
			format.json	{ render :json => questions and return }
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
		question = QualityControlQuestion.find_by_id(params[:id])
		if survey.nil?
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::QUALITY_CONTROL_QUESTION_NOT_EXIST and return }
			end
		end

		retval = question.destroy_quality_control_question(@current_user)
		respond_to do |format|
			format.json	{ render :json => retval and return }
		end
	end

end
