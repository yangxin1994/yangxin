# coding: utf-8

class FaqsController < ApplicationController

	before_filter :require_admin, :except=>[:index, :show]
 
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

		@faqs = @faqs || []

		respond_to do |format|
			format.html # index.html.erb
			format.json { render json: @faqs, :except => [:user_id]}
		end
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

	# GET /faqs/new
	# GET /faqs/new.json
	def new
		@faq = Faq.new

		respond_to do |format|
			format.html # new.html.erb
			format.json { render json: @faq, :except => [:user_id] }
		end
	end

	# GET /faqs/1/edit
	def edit
		@faq = Faq.find_by_id(params[:id])

		respond _to do |format|
			format.html # show.html.erb
			format.json { render json: @system_user, :except => [:user_id] }
		end
	end
	
	# POST /faqs
	# POST /faqs.json
	def create
		@faq = Faq.create_faq(params[:faq], @current_user)	
			
		respond_to do |format|
			format.html  if @faq.instance_of?(Faq)
			format.html { render action: "new" } if !@faq.instance_of?(Faq)
			format.json { render :json => @faq, :except => [:user_id]}
		end
	end

	# PUT /faqs/1
	# PUT /faqs/1.json
	def update
		@faq = Faq.update_faq(params[:id], params[:faq], @current_user)

		respond_to do |format|
			format.html { redirect_to @faq} if @faq.instance_of?(Faq)
			format.html { render action: "edit" } if !@faq.instance_of?(Faq)
			format.json { render :json => @faq,:except => [:user_id] }
		end
	end

	# DELETE /faqs/1
	# DELETE /faqs/1.json
	def destroy
		@faq = Faq.destroy_by_id(params[:id])

		respond_to do |format|
			format.html { redirect_to faqs_url }
			format.json { render :json => @faq,:except => [:user_id] }
		end
	end
	
end
