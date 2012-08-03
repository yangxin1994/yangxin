# coding: utf-8

class FeedbacksController < ApplicationController

	before_filter :require_sign_in, :except => [:new, :create]
	before_filter :require_admin, :only => [:index, :reply]

	# GET /feedbacks
	# GET /feedbacks.json
	def index
		if !params[:feedback_type].nil? then
			if !params[:value].nil? then
				@feedbacks = Feedback.list_by_type_and_value(params[:feedback_type], params[:value])
			elsif !params[:answer].nil? then
				if params[:answer].to_s.strip == "true" then
					@feedbacks = Feedback.list_by_type_and_answer(params[:feedback_type], true)
				elsif params[:answer].to_s.strip == "false" then
					@feedbacks = Feedback.list_by_type_and_answer(params[:feedback_type], false)
				end
			else
				@feedbacks = Feedback.list_by_type(params[:feedback_type])
			end
		else
			@feedbacks = Feedback.all.desc(:updated_at)
		end

		@feedbacks = slice((@feedbacks || []), params[:page], params[:per_page])

		respond_to do |format|
			format.html # index.html.erb
			format.json { render json: @feedbacks }
		end
	end
	
	# GET /feedbacks/1 
	# GET /feedbacks/1.json
	def show
		@feedback = Feedback.find_by_id(params[:id])

		respond _to do |format|
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
		@feedback = Feedback.find_by_id(params[:id])

		respond _to do |format|
			format.html # show.html.erb
			format.json { render json: @feedback }
		end
	end
	
	# POST /feedbacks
	# POST /feedbacks.json
	def create
		@feedback = Feedback.create_feedback(params[:feedback], @current_user)	
			
		respond_to do |format|
			format.html  if @feedback.instance_of?(Feedback)
			format.html { render action: "new" } if !@feedback.instance_of?(Feedback)
			format.json { render :json => @feedback}
		end
	end

	# PUT /feedbacks/1
	# PUT /feedbacks/1.json
	def update
		@feedback = Feedback.update_feedback(params[:id], params[:feedback], @current_user)

		respond_to do |format|
			format.html { redirect_to @feedback} if @feedback.instance_of?(Feedback)
			format.html { render action: "edit" } if !@feedback.instance_of?(Feedback)
			format.json { render :json => @feedback }
		end
	end

	# DELETE /feedbacks/1
	# DELETE /feedbacks/1.json
	def destroy
		retval = Feedback.destroy_by_id(params[:id], @current_user)

		respond_to do |format|
			format.html { redirect_to feedbacks_url }
			format.json { render :json => retval }
		end
	end
	
	# POST /feedbacks/reply
	# POST /feedbacks/reply.json
	def reply
		params[:id] = params[:id] || ""
		params[:message_content] = params[:message_content] || ""

		@feedback = Feedback.where(params[:id]).first
		retval = Feedback.reply(params[:id], @current_user, params[:message_content])

		respond_to do |format|
			format.html { redirect_to @feedback} if @feedback
			format.json { head :json => retval }
		end
	end
	
end
