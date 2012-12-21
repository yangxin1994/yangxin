# coding: utf-8

class Admin::FeedbacksController < Admin::ApplicationController

	def maping_question_user(feedback)
		feedback["question_user_email"] = User.find(feedback["question_user_id"].to_s).email
		feedback
	end

	def maping_answer_user(feedback)
		unless feedback["answer_user_id"].to_s.empty?
			feedback["answer_user_email"] = User.find(feedback["answer_user_id"].to_s).email
		end
		feedback
	end

	# GET /admin/feedbacks
	# GET /admin/feedbacks.json
	def index
		# if !params[:feedback_type].nil? then
		# 	if !params[:value].nil? then
		# 		@feedbacks = Feedback.list_by_type_and_value(params[:feedback_type], params[:value])
		# 	elsif !params[:answer].nil? then
		# 		@feedbacks = Feedback.list_by_type_and_answer(params[:feedback_type], params[:answer].to_s.strip == "true")
		# 	else
		# 		@feedbacks = Feedback.list_by_type(params[:feedback_type])
		# 	end

		# 	@feedbacks = slice((@feedbacks || []), page, per_page)
		# else
		# 	@feedbacks = Feedback.all.asc(:is_answer).desc(:created_at).page(page).per(per_page) 
		# end

		# @feedbacks = @feedbacks.map{|e| maping_question_user(e)}

		# if !params[:feedback_type].nil? then
		# 	if !params[:value].nil? then
		# 		render_json_auto (auto_paginate(@feedbacks, Feedback.list_by_type_and_value(params[:feedback_type], params[:value]).count){@feedbacks}) and return 
		# 	elsif !params[:answer].nil? then
		# 		render_json_auto (auto_paginate(@feedbacks, Feedback.list_by_type_and_answer(params[:feedback_type], params[:answer].to_s.strip == "true").count){@feedbacks}) and return 
		# 	else
		# 		render_json_auto (auto_paginate(@feedbacks, Feedback.list_by_type(params[:feedback_type]).count){@feedbacks}) and return 
		# 	end
		# else
		# 	render_json_auto (auto_paginate(@feedbacks, Feedback.count){@feedbacks}) and return 
		# end

		@feedbacks = Feedback.all 
		if params[:feedback_type]
			types = []
			Feedback::MAX_TYPE.downto(0).each { |element| 
				if params[:feedback_type].to_i / (2**element) == 1 then
					types << 2**element
				end
			}
			@feedbacks = @feedbacks.where(:feedback_type.in => types)
		end
		@feedbacks = @feedbacks.where(:value => Regexp.new(params[:value].to_s)) if params[:value]
		@feedbacks =  @feedbacks.where(:is_answer => params[:answer].to_s == 'true') if params[:answer]
			
		render_json_auto auto_paginate(@feedbacks)
	end
	
	# GET /admin/feedbacks/1 
	# GET /admin/feedbacks/1.json
	def show
		@feedback = Feedback.find_by_id(params[:id])
		@feedback = maping_question_user(maping_answer_user(@feedback)) if @feedback.is_a? Feedback

		respond_to do |format|
			format.html # show.html.erb
			format.json { render_json_auto @feedback }
		end
	end
	
=begin
	# GET /admin/feedbacks/new
	# GET /admin/feedbacks/new.json
	def new
		@feedback = Feedback.new

		respond_to do |format|
			format.html # new.html.erb
			format.json { render json: @feedback }
		end
	end

	# GET /admin/feedbacks/1/edit
	def edit
		@feedback = Feedback.find_by_id(params[:id])

		respond _to do |format|
			format.html # show.html.erb
			format.json { render json: @feedback }
		end
	end
	
	# POST /admin/feedbacks
	# POST /admin/feedbacks.json
	def create
		@feedback = Feedback.create_feedback(params[:feedback], @current_user)	
			
		respond_to do |format|
			format.html  if @feedback.instance_of?(Feedback)
			format.html { render action: "new" } if !@feedback.instance_of?(Feedback)
			format.json { render :json => @feedback}
		end
	end

	# PUT /admin/feedbacks/1
	# PUT /admin/feedbacks/1.json
	def update
		@feedback = Feedback.update_feedback(params[:id], params[:feedback], @current_user)

		respond_to do |format|
			format.html { redirect_to @feedback} if @feedback.instance_of?(Feedback)
			format.html { render action: "edit" } if !@feedback.instance_of?(Feedback)
			format.json { render :json => @feedback }
		end
	end
=end

	# DELETE /admin/feedbacks/1
	# DELETE /admin/feedbacks/1.json
	def destroy
		retval = Feedback.destroy_by_id(params[:id], @current_user)

		respond_to do |format|
			format.html { redirect_to feedbacks_url }
			format.json { render_json_auto retval }
		end
	end
	
	# POST /admin/feedbacks/:id/reply
	# POST /admin/feedbacks/:id/reply.json
	def reply
		params[:id] = params[:id] || ""
		params[:message_content] = params[:message_content] || ""
		@feedback = Feedback.where(_id: params[:id]).first
		retval = Feedback.reply(params[:id], @current_user, params[:message_content])

		respond_to do |format|
			format.html { redirect_to @feedback} if @feedback
			format.json { render_json_auto retval }
		end
	end
	
end
