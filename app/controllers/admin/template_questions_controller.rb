# encoding: utf-8
require 'error_enum'
class Admin::TemplateQuestionsController < Admin::ApplicationController
	before_filter :check_template_question_existence, :only => [:update, :show, :destroy]

	def check_template_question_existence
		@template_question = TemplateQuestion.find_by_id(params[:id])
		if @template_question.nil?
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::TEMPLATE_QUESTION_NOT_EXIST) and return }
			end
		end
	end

	def get_text
		@question = BasicQuestion.find_by_id(params[:id])
		render_json_auto(ErrorEnum::QUESTION_NOT_EXIST) and return unless @question
		render_json_auto @question.content["text"]
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
		template_question = TemplateQuestion.create_question(params[:question_type].to_i, @current_user)
		respond_to do |format|
			format.json	{ render_json_auto(template_question) and return }
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
		template_question = @template_question.update_question(params[:question], @current_user)
		respond_to do |format|
			format.json	{ render_json_auto(template_question) and return }
		end
	end

	def index
		questions = TemplateQuestion.all.page(page).per(per_page)
		respond_to do |format|
			format.json	{ render_json_auto(questions) and return }
		end
	end

	def count
		render_json_auto TemplateQuestion.count
	end

	def list_by_type
		questions = TemplateQuestion.where(question_type: params[:question_type].to_i)
		render_json_auto auto_paginate(questions)
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
		respond_to do |format|
			format.json	{ render_json_auto(@template_question) and return }
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
		retval = @template_question.destroy
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end

end
