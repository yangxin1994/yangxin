# coding: utf-8

class FaqsController < ApplicationController

	before_filter :require_admin, :except=>[:index, :show, :condition]
 
	# GET /faqs
	# GET /faqs.json
	def index
		@faqs = Faq.all.desc(:updated_at)

		respond_to do |format|
			format.html # index.html.erb
			format.json { render json: @faqs }
		end
	end
	
		# GET /faqs/1 
	# GET /faqs/1.json
	def show
		@faq = Faq.find(params[:id])

		respond _to do |format|
			format.html # show.html.erb
			format.json { render json: @faq }
		end
	end

	# GET /faqs/new
	# GET /faqs/new.json
	def new
		@faq = Faq.new

		respond_to do |format|
			format.html # new.html.erb
			format.json { render json: @faq }
		end
	end

	# GET /faqs/1/edit
	def edit
		@faq = Faq.find(params[:id])
	end
	
	# POST /faqs
	# POST /faqs.json
	def create
		@faq = Faq.new(params[:faq])
		@faq.user = current_user		
			
		respond_to do |format|
			if @faq.save
				format.html { redirect_to @faq, notice: "添加成功。" }
				format.json { render json: @faq, status: :created, location: @faq }
			else
				format.html { render action: "new" }
				format.json { render json: @faq.errors, status: :unprocessable_entity }
			end
		end 
	end

	# PUT /faqs/1
	# PUT /faqs/1.json
	def update
		@faq = Faq.find(params[:id])

		respond_to do |format|
			if @faq.update_attributes(params[:faq])
				@faq.user = current_user
				if @faq.save then
					format.html { redirect_to @faq, notice: "更新成功。" }
					format.json { head :ok }
				end
			else
				format.html { render action: "edit" }
				format.json { render json: @faq.errors, status: :unprocessable_entity }
			end
		end
	end

	# DELETE /faqs/1
	# DELETE /faqs/1.json
	def destroy
		@faq = Faq.find(params[:id])
		@faq.destroy

		respond_to do |format|
			format.html { redirect_to faqs_url }
			format.json { head :ok }
		end
	end
	
	# GET /faqs/condition/:type/:value
	# GET /faqs/condition/:type/:value.json
	def condition
		type = params[:type].to_i
		value = params[:value]
		
		@faqs = Faq.find_by_type(type, value)
		
		respond_to do |format|
			format.html # index.html.erb
			format.json { render json: @faqs }
		end
	end
	
end
