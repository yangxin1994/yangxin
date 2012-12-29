# coding: utf-8

class FaqsController < ApplicationController
 
	# GET /faqs
	# GET /faqs.json
	def index
		@faqs = Faq.all 
		if params[:faq_type]
			types = []
			FAQ::MAX_TYPE.downto(0).each { |element| 
				if params[:faq_type].to_i / (2**element) == 1 then
					types << 2**element
				end
			}
			@faqs = @faqs.where(:faq_type.in => types)
		end
		@faqs = @faqs.where(:value => Regexp.new(params[:value].to_s)) if params[:value]
			
		render_json_auto auto_paginate(@faqs.desc(:created_at))
	end
	
	# GET /faqs/1 
	# GET /faqs/1.json
	def show
		@faq = Faq.find_by_id(params[:id])

		respond_to do |format|
			format.html # show.html.erb
			format.json { render_json_auto @faq, :except => [:user_id] }
		end
	end
	
end
