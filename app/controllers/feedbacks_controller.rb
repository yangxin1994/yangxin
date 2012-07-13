# coding: utf-8

class FeedbacksController < ApplicationController

	before_filter :require_admin, :only => [:reply]

	# GET /feedbacks
	# GET /feedbacks.json
	def index
		
		answer_var = params[:answer]
	
		if answer_var && answer_var == "true" then
			@feedbacks = Feedback.answered
		elsif answer_var && answer_var == "false" then
			@feedbacks = Feedback.unanswer
		else
			@feedbacks = Feedback.all.desc(:updated_at)
		end

		respond_to do |format|
			format.html # index.html.erb
			format.json { render json: @feedbacks }
		end
	end

	# GET /feedbacks/1
	# GET /feedbacks/1.json
	def show
		@feedback = Feedback.find(params[:id])

		respond_to do |format|
			format.html # show.html.erb
			format.json { render json: @feedback }
		end
	end

	# GET /feedbacks/new
	# GET /feedbacks/new.json
	def new
		@feedback = Feedback.new

		respond_to do |format|
			format.html # new.html.erb
			format.json { render json: @feedback }
		end
	end

	# GET /feedbacks/1/edit
	def edit
		@feedback = Feedback.find(params[:id])
	end

	# POST /feedbacks
	# POST /feedbacks.json
	def create
		@feedback = Feedback.new(params[:feedback])
		@feedback.question_user = current_user if current_user

		respond_to do |format|
			if @feedback.save
				format.html { redirect_to @feedback, notice: "添加成功。" }
				format.json { render json: @feedback, status: :created, location: @feedback }
			else
				format.html { render action: "new" }
				format.json { render :json => ErrorEnum::SAVE_FAILED}
			end
		end
	rescue => ex 
		if ex.class == TypeError then
			respond_to do |format|
				format.html { render action: "new"}
				format.json { render :json => {:error => ErrorEnum::TYPE_ERROR}}
			end
		elsif ex.class == RangeError then
			respond_to do |format|
				format.html { render action: "new" }
				format.json { render :json => {:error => ErrorEnum::RANGE_ERROR}}
			end
		else
			respond_to do |format|
				format.html { render action: "new" }
				format.json { render :json => {:error => ErrorEnum::SAVE_FAILED}}
			end
		end
	end

	# PUT /feedbacks/1
	# PUT /feedbacks/1.json
	def update
		@feedback = Feedback.find(params[:id])
		
		require_sign_in if @feedback.question_user
		
		if @feedback.question_user && @feedback.question_user != current_user then
			format.html { render action: "edit"}
			format.json { render :json => ErrorEnum::SAVE_FAILED}
		end

		respond_to do |format|
			if @feedback.update_attributes(params[:feedback])
				format.html { redirect_to @feedback, notice: "更新成功。" }
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
				format.json { render :json => {:error => ErrorEnum::TYPE_ERROR}}
			end
		elsif ex.class == RangeError then
			respond_to do |format|
				format.html { render action: "edit" }
				format.json { render :json => {:error => ErrorEnum::RANGE_ERROR}}
			end
		else
			respond_to do |format|
				format.html { render action: "edit" }
				format.json { render :json => {:error => ErrorEnum::SAVE_FAILED}}
			end
		end
	end

	# DELETE /feedbacks/1
	# DELETE /feedbacks/1.json
	def destroy
		@feedback = Feedback.find(params[:id])
		@feedback.destroy

		respond_to do |format|
			format.html { redirect_to feedbacks_url }
			format.json { render :json => true }
		end
	end
	
	# POST /feedbacks/1/reply
	# POST /feedbacks/1/reply.json
	def reply
		@feedback = Feedback.find(params[:id])
		message_content = params[:message_content]
		
		if @feedback and message_content and message_content !="" then
		
			stat = Feedback.reply(params[:id], current_user, message_content)
			
			if stat then
				respond_to do |format|
					format.html { redirect_to @feedback, notice: "回复成功。" }
					format.json { render :json => true}
				end
			else
				respond_to do |format|
					format.html { redirect_to @feedback, notice: "回复失败。" }
					format.json { head :json => ErrorEnum::SAVE_FAILED }
				end
			end
		else
			respond_to do |format|
				format.html { redirect_to @feedback, notice: "回复失败。" }
				format.json { head :json => ErrorEnum::SAVE_FAILED }
			end
		end
	end
	
	# GET /feedbacks/condition
	# GET /feedbacks/condition.json
	def condition
		type = params[:type] || 0
		value = params[:value] || ""
		
		@feedbacks = Feedback.condition(type, value)
		
		respond_to do |format|
			format.html
			format.json { render json: @feedbacks }
		end
	rescue => ex 
		if ex.class == TypeError then
			respond_to do |format|
				format.html
				format.json { render :json => {:error => ErrorEnum::TYPE_ERROR}}
			end
		elsif ex.class == RangeError then
			respond_to do |format|
				format.html
				format.json { render :json => {:error => ErrorEnum::RANGE_ERROR}}
			end
		elsif ex.class == ArgumentError then
			respond_to do |format|
				format.html
				format.json { render :json => {:error => ErrorEnum::ARG_ERROR}}
			end
		else
			respond_to do |format|
				format.html
				format.json { render :json => {:error => ErrorEnum::UNKNOWN_ERROR}}
			end
		end
	end

	# GET /feedbacks/types
	# GET /feedbacks/types.json
	def types
		type = params[:type] || 0

		@feedbacks = Feedback.find_by_type(type)
		
		respond_to do |format|
			format.html
			format.json { render json: @feedbacks }
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
