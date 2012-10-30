# encoding: utf-8
require 'error_enum'
class QualityControlQuestionsController < ApplicationController
	before_filter :require_sign_in
	before_filter :check_quality_control_question_existence, :only => [:show]

	def check_quality_control_question_existence
		@question = QualityControlQuestion.find_by_id(params[:id])
		if @question.nil?
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::QUALITY_CONTROL_QUESTION_NOT_EXIST) and return }
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
		question = @question.show_quality_control_question(@current_user)
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

end
