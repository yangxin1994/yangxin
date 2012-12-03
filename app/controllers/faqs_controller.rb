# coding: utf-8

class FaqsController < ApplicationController
 
	# GET /faqs
	# GET /faqs.json
	def index
		if !params[:faq_type].nil? then
			if !params[:value].nil? then
				@faqs = Faq.list_by_type_and_value(params[:faq_type], params[:value])
			else
				@faqs = Faq.list_by_type(params[:faq_type])
			end
		else
			@faqs = Faq.all.desc(:updated_at)
		end

		@show_faqs = slice((@faqs || []), params[:page], params[:per_page])

		render_json_auto (auto_paginate(@show_faqs, @faqs.count){@show_faqs}) and return
	end
	
	# GET /faqs/1 
	# GET /faqs/1.json
	def show
		@faq = Faq.find_by_id(params[:id])

		respond_to do |format|
			format.html # show.html.erb
			format.json { render json: @faq, :except => [:user_id] }
		end
	end
	
end
