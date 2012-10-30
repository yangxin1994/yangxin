# encoding: utf-8
require 'error_enum'
class Admin::QualityControlQuestionsController < Admin::ApplicationController
	before_filter :check_quality_control_question_existence, :only => [:update, :show, :destroy, :update_answer]

	def check_quality_control_question_existence
		@question = QualityControlQuestion.find_by_id(params[:id])
		if @question.nil?
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::QUALITY_CONTROL_QUESTION_NOT_EXIST) and return }
			end
		end
	end

	#*method*: post
	#
	#*url*: /quality_control_questions
	#
	#*description*: create a new quality control question
	#
	#*params*:
	#* quality_control_type: type of the quality control question, 1 for objective questions, 2 for matching questions
	#* question_type: type of the question, please check lib/question_type_enum.rb
	#* question_number: number of questions, only for matching question
	#
	#*retval*:
	#* an array, the formal elements of which are questions created, and the last element is the quality control answer object: when successfully created
	#* ErrorEnum::WRONG_QUALITY_CONTROL_TYPE
	#* ErrorEnum::WRONG_QUESTION_TYPE
	def create
		quality_control_question = QualityControlQuestion.create_quality_control_question(params[:quality_control_type].to_i, params[:question_type].to_i, params[:question_number].to_i)
		respond_to do |format|
			format.json	{ render_json_auto(quality_control_question) and return }
		end
	end

	#*method*: put
	#
	#*url*: /quality_control_questions/:quality_control_question_id
	#
	#*description*: update a quality control question
	#
	#*params*:
	#* quality_control_question_id: id of the question to be updated
	#* question: the question object to be updated
	#
	#*retval*:
	#* question object: when question is successfully updated
	#* ErrorEnum ::QUESTION_NOT_EXIST: when the question does not exist
	#* ErrorEnum ::UNAUTHORIZED: when the operator is not admin
	#* ErrorEnum ::WRONG_DATA_TYPE: when the data type specified in a blank question is wrong
	def update
		question = @question.update_question(params[:question], @current_user)
		respond_to do |format|
			format.json	{ render_json_auto(question) and return }
		end
	end

	def update_answer
		retval = QualityControlQuestionAnswer.update_answer(params[:id], params[:quality_control_type].to_i, params[:answer])
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
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
		question = @question.show_quality_control_question
		respond_to do |format|
			format.json	{ render_json_auto(question) and return }
		end
	end

	def index
		questions = QualityControlQuestion.list_quality_control_question(params[:quality_control_type].to_i)
		respond_to do |format|
			format.json	{ render_json_auto(questions) and return }
		end
	end

	def objective_questions
		questions = QualityControlQuestion.objective_questions.desc(:created_at).page(page).per(per_page)
		respond_to do |format|
			format.json	{ render_json_auto(questions) and return }
		end
	end

	def objective_questions_count
		render_json_auto QualityControlQuestion.objective_questions.count
	end

	def matching_questions
		questions = QualityControlQuestion.matching_questions.desc(:created_at).page(page).per(per_page)
		respond_to do |format|
			format.json	{ render_json_auto(questions) and return }
		end
	end

	def matching_questions_count
		render_json_auto QualityControlQuestion.matching_questions.count
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
		retval = @question.delete_quality_control_question(@current_user)
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end

end
