class Admin::SurveysController < Admin::ApplicationController
	before_filter :check_survey_existence, :except => [:index]
	before_filter :check_reward_scheme_existence, :only => [:quillme_promote, :email_promote, :sms_promote, :weibo_promote, :broswer_extension_promote, ]

	def check_survey_existence
		@survey = Survey.find_by_id(params[:id])
		render_json_auto(ErrorEnum::SURVEY_NOT_EXIST) and return if @survey.nil?
	end

	def check_reward_scheme_existence
		@reward_scheme = RewardScheme.find_by_id(params[:reward_scheme_id])
		render_json_auto(ErrorEnum::REWARD_SCHEME_NOT_EXIST) and return if @reward_scheme.nil?
	end

	def index
		select_fileds = {}
		if !params[:status].blank?   ## status filter
			status_filter = Tool.convert_int_to_base_arr(params[:status].to_i)
			select_fileds[:status] = {"$in" => status_filter}
		end
		select_fileds[:title] = /.*#{params[:title]}.*/ if !params[:title].blank?  ## title filter
		@surveys = Survey.find_by_fields(select_fileds)

		@surveys = find_by_user_fields(@surveys, [:email, :mobile])  ## user moblile and email filter
		@surveys = @surveys.map { |s| s.append_user_fields([:email, :mobile]) }
		@surveys = @surveys.map { |s| s.serialize_for([:title, :email, :mobile, :created_at]) }
		render_json_auto auto_paginate(@surveys) and return
	end

	def show
	    s = @survey.attributes
		s['created_at'] = s['created_at'].to_i
		s['updated_at'] = s['updated_at'].to_i
		render_json_auto s and return
	end

	def promote
		retval = {}
		retval["quillme"] = @survey.quillme_promote
		retval["email"] = @survey.email_promote
		retval["sms"] = @survey.sms_promote
		retval["broswer_extension"] = @survey.broswer_extension_promote
		retval["weibo"] = @survey.weibo_promote
		render_json_auto retval and return
	end

	def quillme_promote
		@survey.update_attributes({'quillme_promote' => params[:quillme_promote_setting]})
		render_json_auto true and return
	end

	def email_promote
		@survey.update_attributes({'email_promote' => params[:email_promote_setting]})
		render_json_auto true and return
	end

	def sms_promote
		@survey.update_attributes({'sms_promote' => params[:sms_promote_setting]})
		render_json_auto true and return
	end

	def broswer_extension_promote
		@survey.update_attributes({'broswer_extension_promote' => params[:broswer_extension_promote_setting]})
		render_json_auto true and return
	end

	def weibo_promote
		@survey.update_attributes({'weibo_promote' => params[:weibo_promote_setting]})
		render_json_auto true and return
	end

	def  background_survey
		@survey.update_attributes({'delta' => params[:delta_setting]})
		render_json_auto true and return
	end

	def find_by_user_fields(surveys, arr_fields)
		arr_fields.each do |field|
			if !params[field].blank?
				surveys = surveys.to_a.select do |s|
					s.user.send(field).include?(params[field].to_s)
				end
			end
		end
		surveys
	end

	def quillme_hot
		render_json_auto @survey.set_quillme_hot and return
	end

	def add_template_question
		@survey = Survey.find_by_id(params[:id]) if params[:id]
		unless @survey
			@survey = Survey.create
			@current_user.surveys << @survey
		end
		if params[:question_id]
			# insert
			@survey.insert_template_question( params[:page_index].to_s.to_i,
					"-1", params[:question_id])
			# convert
			@survey.convert_template_question_to_normal_question(params[:question_id])
		end
		render_json_auto true
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

	def set_promotable
		@survey = Survey.normal.find_by_id(params[:id])
		render_json_auto(ErrorEnum::SURVEY_NOT_EXIST) and return if @survey.nil?
		@survey.promotable = params[:promotable].to_s == "true"
		@survey.promote_email_number = params[:promote_email_number].to_i if !params[:promote_email_number].nil?
		render_json_auto(@survey.save) and return
	end

	def get_sent_email_number
		@survey = Survey.normal.find_by_id(params[:id])
		render_json_auto(ErrorEnum::SURVEY_NOT_EXIST) and return if @survey.nil?
		sent_email_number = @survey.email_histories.length
		render_json_auto(sent_email_number) and return
	end

	def set_answer_need_review
		@survey = Survey.normal.find_by_id(params[:id])
		render_json_auto(ErrorEnum::SURVEY_NOT_EXIST) and return if @survey.nil?
		@survey.answer_need_review = params[:answer_need_review].to_s == "true"
		render_json_auto(@survey.save) and return
	end

	def destroy
		@survey = Survey.find_by_id(params[:id])
		# else just change status to -1
		render_json_auto @survey.try(:delete) and return
	end

end