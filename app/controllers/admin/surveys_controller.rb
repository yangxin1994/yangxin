class Admin::SurveysController < Admin::ApplicationController

	def index

		@surveys = Survey.where(:user_attr_survey => false)
		# use publish_status = 0 means status=-1
		if params[:publish_status].to_i > 0
			@surveys = @surveys.where(:status.gt => -1, :publish_status => params[:publish_status].to_i).desc(:created_at) 
		elsif params[:publish_status] && params[:publish_status].to_i == 0
			@surveys = @surveys.where(:status => -1).desc(:created_at)
		end
		@surveys = @surveys.where(:show_in_community => params["show_in_community"].to_s == 'true') if params[:show_in_community]
		# search 
		@surveys = @surveys.where(title: /.*#{params[:title]}.*/) if params[:title]
		
		if params[:email].nil?
			render_json_auto auto_paginate(@surveys) and return
		else
			@surveys = @surveys.to_a.select do |s|
				s.user.email.include?(params[:email].to_s)
			end

			render_json_auto auto_paginate(@surveys) and return
		end
	end

	def show
		@survey = Survey.normal.find_by_id(params[:id])
		render_json_auto(ErrorEnum::SURVEY_NOT_EXIST) and return unless @survey
		render_json_auto @survey
	end

	def show_user_attr_survey
		@survey = Survey.get_user_attr_survey
		render_json_auto @survey
	end

	def add_template_question
		# if params[:question_ids]
			@survey = Survey.find_by_id(params[:id]) if params[:id]
			unless @survey
				@survey = Survey.create
				@survey.alt_new_survey = false
				@current_user.surveys << @survey
				@survey.set_user_attr_survey(true)
			end
			if params[:question_id]
				# insert
				@survey.insert_template_question( params[:page_index].to_s.to_i, 
						"-1", params[:question_id])
				# convert
				@survey.convert_template_question_to_normal_question(params[:question_id])
			end

			render_json_auto true
		# else
		# 	render_json_auto false
		# end
	end

	def allocate
		@survey = Survey.normal.find_by_id(params[:id])
		render_json_auto(ErrorEnum::SURVEY_NOT_EXIST) and return if @survey.nil?
		retval = @survey.allocate(params[:system_user_type], params[:user_id], params[:allocate].to_s == "true")
		render_json_auto(retval) and return
	end

	def add_reward
		@survey = Survey.normal.find_by_id(params[:id])
		render_json_auto(ErrorEnum::SURVEY_NOT_EXIST) and return unless @survey
		params[:lottery] = Lottery.find_by_id(params[:lottery_id]) if params[:reward].to_i==1
		s = params.select{|k,v| %w(reward point lottery).include?(k.to_s)}
		render_json_auto @survey.update_attributes(s) and return
	end	

	def set_community
		@survey = Survey.normal.find_by_id(params[:id])
		render_json_auto(ErrorEnum::SURVEY_NOT_EXIST) and return if @survey.nil?
		retval = @survey.set_community(params[:show_in_community].to_s == "true")
		render_json_auto(retval) and return
	end

	def set_spread
		@survey = Survey.normal.find_by_id(params[:id])
		render_json_auto(ErrorEnum::SURVEY_NOT_EXIST) and return if @survey.nil?
		retval = @survey.set_spread(params[:spread_point].to_i, params[:spreadable].to_s == "true")
		render_json_auto(retval) and return
	end

	def destroy
		@survey = Survey.find_by_id(params[:id])
		# new_survey which is not edited should be remove from db
		render_json_auto @survey.destroy and return if @survey && @survey.new_survey == true
		# else just change status to -1
		render_json_auto @survey.delete and return if @survey && @survey.new_survey == false
		render_json_auto false
	end

end