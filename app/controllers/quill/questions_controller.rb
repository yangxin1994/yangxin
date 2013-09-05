# finish migrating
class Quill::QuestionsController < ApplicationController
	
	before_filter :require_sign_in, :ensure_survey
		
	def ensure_survey
		@survey = Survey.find_by_id(params[:questionaire_id])
		render_json_e ErrorEnum::SURVEY_NOT_EXIST and return if @survey.nil?
		# @ws_client = Quill::PageClient.new(session_info, params[:questionaire_id])
	end

	# create question. 
	# if after_question_id is -1, insert at the last of the page
	# if after_question_id is 0, insert at the begining of the page
	def create
		retval = @survey.create_question(params[:page_index].to_i, params[:after_question_id], params[:question_type].to_i)
		render_json_auto retval and return
	end

	# get one question
	def show
		question = @survey.get_question_inst(params[:id])
		question = question.serialize if question.class == Question
		render_json_auto question and return
	end

	# update a question
	def update
		question = @survey.update_question(params[:question]['_id'], params[:question])
		render_json_auto question and return
	end

	# destroy a question
	def destroy
		retval = @survey.delete_question(params[:id])
		render_json_auto retval and return
	end

	# move a question
	def move
		retval = @survey.move_question(params[:id], params[:page_index].to_i, params[:after_question_id])
		render_json_auto retval and return
	end
end
