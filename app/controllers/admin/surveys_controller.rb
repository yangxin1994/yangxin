class Admin::SurveysController < Admin::ApplicationController

	def wait_to_community
		@surveys = Survey.normal.where(:publish_status.gt => 2).asc(:show_in_community)
		render_json_auto auto_paginate(@surveys)
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

	def add_questions
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
		s = params[:survey].select{|k,v| %w(reward point lottery).include?(k.to_s)}
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

end