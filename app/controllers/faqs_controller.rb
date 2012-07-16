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
			
		respond_to do |format|
			if @faq.save(current_user)
				format.html { redirect_to @faq, notice: "添加成功。" }
				format.json { render json: @faq, status: :created, location: @faq }
			else
				format.html { render action: "new" }
				format.json { render :json => ErrorEnum::SAVE_FAILED}
			end
		end
	rescue => ex 
		if ex.class == TypeError then
			respond_to do |format|
				format.html { render action: "new"}
				format.json { render :json => ErrorEnum::TYPE_ERROR}
			end
		elsif ex.class == RangeError then
			respond_to do |format|
				format.html { render action: "new" }
				format.json { render :json => ErrorEnum::RANGE_ERROR}
			end
		else
			respond_to do |format|
				format.html { render action: "new" }
				format.json { render :json => ErrorEnum::SAVE_FAILED}
			end
		end
	end

	# PUT /faqs/1
	# PUT /faqs/1.json
	def update
		@faq = Faq.find(params[:id])

		respond_to do |format|
			if @faq.update_attributes(params[:faq],current_user)
				format.html { redirect_to @faq, notice: "更新成功。" }
				format.json { render :json => true }
			else
				format.html { render action: "edit" }
				format.json { render :json => ErrorEnum::SAVE_FAILED }
			end
		end
	rescue => ex 
		if ex.class == TypeError then
			respond_to do |format|
				format.html { render action: "edit"}
				format.json { render :json => ErrorEnum::TYPE_ERROR}
			end
		elsif ex.class == RangeError then
			respond_to do |format|
				format.html { render action: "edit" }
				format.json { render :json => ErrorEnum::RANGE_ERROR}
			end
		else
			respond_to do |format|
				format.html { render action: "edit" }
				format.json { render :json => ErrorEnum::SAVE_FAILED}
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
			format.json { render :json => true }
		end
	end
	
	# GET /faqs/condition
	# GET /faqs/condition.json
	def condition
		type = params[:type] || 0
		value = params[:value] || ""
		@faqs = Faq.condition(type, value)
		
		respond_to do |format|
			format.html
			format.json { render json: @faqs }
		end
	rescue => ex 
		if ex.class == TypeError then
			respond_to do |format|
				format.html
				format.json { render :json => ErrorEnum::TYPE_ERROR}
			end
		elsif ex.class == RangeError then
			respond_to do |format|
				format.html
				format.json { render :json => ErrorEnum::RANGE_ERROR}
			end
		elsif ex.class == ArgumentError then
			respond_to do |format|
				format.html
				format.json { render :json => ErrorEnum::ARG_ERROR}
			end
		else
			respond_to do |format|
				format.html
				format.json { render :json => ErrorEnum::UNKNOWN_ERROR}
			end
		end
	end
	
	# GET /faqs/types
	# GET /faqs/types.json
	def types
		type = params[:type] || 0
		@faqs = Faq.find_by_type(type)
		
		respond_to do |format|
			format.html
			format.json { render json: @faqs }
		end
	rescue => ex 
		if ex.class == TypeError then
			respond_to do |format|
				format.html
				format.json { render :json => ErrorEnum::TYPE_ERROR}
			end
		elsif ex.class == RangeError then
			respond_to do |format|
				format.html
				format.json { render :json => ErrorEnum::RANGE_ERROR}
			end
		elsif ex.class == ArgumentError then
			respond_to do |format|
				format.html
				format.json { render :json => ErrorEnum::ARG_ERROR}
			end
		else
			respond_to do |format|
				format.html
				format.json { render :json => ErrorEnum::UNKNOWN_ERROR}
			end
		end
	end
end
