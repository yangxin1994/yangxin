class Quill::PagesController < ApplicationController
	
	before_filter :require_sign_in, :get_ws_client
	
	def get_ws_client
		@ws_client = Quill::PageClient.new(session_info, params[:questionaire_id])
	end

	# create page
	def create
		render :json => @ws_client.new_page(params['page_index'].to_i)
	end

	# split one page into two pages.
	# If before_question_id is -1, split at the last of the page.
	def split
		render :json => @ws_client.split_page(params['id'].to_i, params['before_question_id'])
	end

	# combine pages
	def combine
		render :json => @ws_client.combine_pages(params['id'].to_i)
	end

	# get one page questions
	def show
		render :json => @ws_client.get_page_questions(params['id'].to_i)
	end

end
