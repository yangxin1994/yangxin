# coding: utf-8

class Admin::FaqsController < Admin::ApplicationController

	def maping(faq)
		faq['user_email'] = User.find(faq['user_id'].to_s).email
		faq
	end
 
	# GET /admin/faqs
	# GET /admin/faqs.json
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
	
	# GET /admin/faqs/1 
	# GET /admin/faqs/1.json
	def show
		@faq = Faq.find_by_id(params[:id])
		@faq = maping(@faq) if @faq.is_a? Faq

		respond_to do |format|
			format.html # show.html.erb
			format.json { render_json_auto @faq }
		end
	end

	# GET /admin/faqs/new
	# GET /admin/faqs/new.json
	def new
		@faq = Faq.new

		respond_to do |format|
			format.html # new.html.erb
			format.json { render_json_auto @faq }
		end
	end

	# GET /admin/faqs/1/edit
	def edit
		@faq = Faq.find_by_id(params[:id])

		respond _to do |format|
			format.html # show.html.erb
			format.json { render_json_auto @faq }
		end
	end
	
	# POST /admin/faqs
	# POST /admin/faqs.json
	def create
		@faq = Faq.create_faq(params[:faq], @current_user)	
			
		respond_to do |format|
			format.html  if @faq.instance_of?(Faq)
			format.html { render action: "new" } if !@faq.instance_of?(Faq)
			format.json { render_json_auto @faq}
		end
	end

	# PUT /admin/faqs/1
	# PUT /admin/faqs/1.json
	def update
		@faq = Faq.update_faq(params[:id], params[:faq], @current_user)

		respond_to do |format|
			format.html { redirect_to @faq} if @faq.instance_of?(Faq)
			format.html { render action: "edit" } if !@faq.instance_of?(Faq)
			format.json { render_json_auto @faq}
		end
	end

	# DELETE /admin/faqs/1
	# DELETE /admin/faqs/1.json
	def destroy
		@faq = Faq.destroy_by_id(params[:id])

		respond_to do |format|
			format.html { redirect_to faqs_url }
			format.json { render_json_auto @faq}
		end
	end
	
end
