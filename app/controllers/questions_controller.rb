# encoding: utf-8
require 'error_enum'
class QuestionsController < ApplicationController
	before_filter :require_sign_in, :check_normal_survey_existence


	def check_normal_survey_existence
		@survey = @current_user.is_admin ? Survey.normal.find_by_id(params[:survey_id]) : @current_user.surveys.normal.find_by_id(params[:survey_id])
		if @survey.nil?
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::SURVEY_NOT_EXIST) and return }
			end
		end
	end

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
		question = @survey.create_question(params[:page_index].to_i, params[:question_id], params[:question_type].to_i)
		respond_to do |format|
			format.json	{ render_json_auto(question) and return }
		end
	end

	def insert_template_question
		question = @survey.insert_template_question(params[:page_index].to_i, params[:question_id], params[:template_question_id])
		respond_to do |format|
			format.json	{ render_json_auto(question) and return }
		end
	end

	def convert_template_question_to_normal_question
		question = @survey.convert_template_question_to_normal_question(params[:id])
		respond_to do |format|
			format.json	{ render_json_auto(question) and return }
		end
	end

	def insert_quality_control_question
		questions = @survey.insert_quality_control_question(params[:page_index].to_i, params[:question_id], params[:quality_control_question_id])
		respond_to do |format|
			format.json	{ render_json_auto(questions) and return }
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
		question = @survey.update_question(params[:id], params[:question])
		respond_to do |format|
			format.json	{ render_json_auto(question) and return }
		end
	end


	#*method*: put
	#
	#*url*: /surveys/:survey_id/questions/:id/move
	#
	#*description*: move a question after another give question, 
	#if after_question_id is -1, move question_id to the begining of page_index
	#
	#*params*:
	#* survey_id: id of the survey
	#* id: id of the question to be moved
	#* page_index: index of the page, where the question is moved to. Page index starts from 0
	#* after_question_id: id of the question, after which the above question is moved
	#
	#*retval*:
	#* true: when question is successfully moved
	#* ErrorEnum ::SURVEY_NOT_EXIST: when the survey does not exist
	#* ErrorEnum ::QUESTION_NOT_EXIST: when the question does not exist
	#* ErrorEnum ::UNAUTHORIZED: when the survey does not belong to the current user
	def move
		retval = @survey.move_question(params[:id], params[:page_index].to_i, params[:after_question_id])
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
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
	#* question_id: id of the question to be moved
	#* page_index: index of the page, where the question is inserted to. Page index starts from 0
	#* after_question_id: id of the question, after which the cloned question is inserted
	#
	#*retval*:
	#* the cloned question object: when question is successfully cloned
	#* ErrorEnum ::SURVEY_NOT_EXIST: when the survey does not exist
	#* ErrorEnum ::QUESTION_NOT_EXIST: when the question does not exist
	#* ErrorEnum ::OVERFLOW: when the page index is greater than the page number
	#* ErrorEnum ::UNAUTHORIZED: when the survey does not belong to the current user
	def clone
		question = @survey.clone_question(params[:id], params[:page_index].to_i, params[:after_question_id])
		respond_to do |format|
			format.json	{ render_json_auto(question) and return }
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
		question = @survey.get_question_inst(params[:id])
		respond_to do |format|
			format.json	{ render_json_auto(question) and return }
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
		retval = @survey.delete_question(params[:id])
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end
end
