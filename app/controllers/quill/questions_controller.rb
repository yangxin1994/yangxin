class Quill::QuestionsController < ApplicationController
	
	before_filter :require_sign_in, :get_ws_client
		
	def get_ws_client
		@ws_client = Quill::QuestionClient.new(session_info, params[:questionaire_id])
	end

	# create question. 
	# if after_question_id is -1, insert at the last of the page
	# if after_question_id is 0, insert at the begining of the page
	def create
		render :json => @ws_client.new_question(params['page_index'].to_i, 
			params['after_question_id'], params['question_type'].to_i)
	end

	# get one question
	def show
		render :json => @ws_client.get_question(params['id'])
	end

	# update a question
	def update
		render :json => @ws_client.update_question(params['question'])
	end

	# destroy a question
	def destroy
		render :json => @ws_client.delete_question(params['id'])
	end

	# move a question
	def move
		render :json => @ws_client.move_question(params['id'], params['after_question_id'], params['page_index'])
	end

end
