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
				format.json { render json: @feedback.errors, status: :unprocessable_entity }
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
			format.html { render a redirect_to @feedback, notice: "更新失败。" }
			format.json { render json: @feedback.errors, status: :unprocessable_entity }
		end

		respond_to do |format|
			if @feedback.update_attributes(params[:feedback])
				if @feedback.save then
					format.html { redirect_to @feedback, notice: "更新成功。" }
					format.json { head :ok }
				end
			else
				format.html { render action: "edit" }
				format.json { render json: @feedback.errors, status: :unprocessable_entity }
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
			format.json { head :ok }
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
					format.json { head :ok }
				end
			else
				respond_to do |format|
					format.html { redirect_to @feedback, notice: "回复失败。" }
					format.json { head :status => 404 }
				end
			end
		else
			respond_to do |format|
				format.html { redirect_to @feedback, notice: "回复失败。" }
				format.json { head :status => 404 }
			end
		end
	end
	
	# GET /feedbacks/condition
	# GET /feedbacks/condition.json
	def condition
		raise TypeError if params[:type] && params[:type].to_i ==0 && params[:type].strip != "0"
		raise RangeError if params[:type] && (params[:type].to_i < 0 || params[:type].to_i > 2**Feedback::MAX_TYPE)	
		type = params[:type].to_i		
		value = params[:value] || ""
		raise ArgumentError if value.strip == ""
		
		@feedbacks = Feedback.find_by_type(type, value)
		
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
end
