# coding: utf-8

class FeedbacksController < ApplicationController

	before_filter :require_sign_in, :except => [:new, :create]

	# GET /feedbacks
	# GET /feedbacks.json
	def index
		if params[:mine].to_s == 'true'
			@feedbacks = Feedback.where(question_user_id: @current_user.id)
		else
			@feedbacks = Feedback.all 
		end
		
		if params[:feedback_type]
			types = []
			Feedback::MAX_TYPE.downto(0).each { |element| 
				if params[:feedback_type].to_i / (2**element) == 1 then
					types << 2**element
				end
			}
			@feedbacks = @feedbacks.where(:feedback_type.in => types)
		end
		@feedbacks = @feedbacks.where(:title => Regexp.new(params[:title].to_s)) if params[:title]
		@feedbacks =  @feedbacks.where(:is_answer => params[:answer].to_s == 'true') if params[:answer]
			
		render_json_auto auto_paginate(@feedbacks.desc(:created_at))
	end
	
	# GET /feedbacks/1 
	# GET /feedbacks/1.json
	def show
		@feedback = Feedback.find_by_id(params[:id])

		respond_to do |format|
			format.html # show.html.erb
			format.json { render_json_auto @feedback }
		end
	end

	# GET /feedbacks/new
	# GET /feedbacks/new.json
	def new
		@feedback = Feedback.new

		respond_to do |format|
			format.html # new.html.erb
			format.json { render_json_auto @feedback }
		end
	end

	# GET /feedbacks/1/edit
	def edit
		@feedback = Feedback.find_by_id(params[:id])

		respond _to do |format|
			format.html # show.html.erb
			format.json { render_json_auto @feedback }
		end
	end
	
	# POST /feedbacks
	# POST /feedbacks.json
	def create
		@feedback = Feedback.create_feedback(params[:feedback], @current_user)	
			
		respond_to do |format|
			format.html  if @feedback.instance_of?(Feedback)
			format.html { render action: "new" } if !@feedback.instance_of?(Feedback)
			format.json { render_json_auto @feedback}
		end
	end

	# PUT /feedbacks/1
	# PUT /feedbacks/1.json
	def update
		@feedback = Feedback.update_feedback(params[:id], params[:feedback], @current_user)

		respond_to do |format|
			format.html { redirect_to @feedback} if @feedback.instance_of?(Feedback)
			format.html { render action: "edit" } if !@feedback.instance_of?(Feedback)
			format.json { render_json_auto @feedback }
		end
	end

	# DELETE /feedbacks/1
	# DELETE /feedbacks/1.json
	def destroy
		retval = Feedback.destroy_by_id(params[:id], @current_user)

		respond_to do |format|
			format.html { redirect_to feedbacks_url }
			format.json { render_json_auto retval }
		end
	end	
end
