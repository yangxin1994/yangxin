class Admin::SurveysController < Admin::ApplicationController
	before_filter :check_survey_existence, :except => [:index]
	before_filter :check_reward_scheme_existence, :only => [:quillme_promote, :email_promote, :sms_promote, :weibo_promote, :broswer_extension_promote, ]

	def check_survey_existence
		@survey = Survey.find_by_id(params[:id])
		render_json_auto(ErrorEnum::SURVEY_NOT_EXIST) and return if @survey.nil?
	end

	def check_reward_scheme_existence
		reward_scheme_id = params[(params[:action] + "_setting").to_sym]["reward_scheme_id"]
		reward_scheme = RewardScheme.find_by_id(reward_scheme_id)
		render_json_auto(ErrorEnum::REWARD_SCHEME_NOT_EXIST) and return if reward_scheme.nil?
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
		render_json_auto @survey.info_for_admin and return
	end

	def promote
		retval = @survey.get_all_promote_settings
		render_json_auto retval and return
	end

	def quillme_promote
		@survey.update_attributes({
			"quillme_promotable" => params[:promotable],
			'quillme_promote_info' => params[:quillme_promote_setting]
			})
		@survey.update_quillme_promote_reward_type
		render_json_auto true and return
	end

	def email_promote
		email_promote_setting = params[:email_promote_setting]
		email_promote_setting["promote_email_count"] = @survey.email_promote_info["promote_email_count"]
		@survey.update_attributes({
			"email_promotable" => params[:promotable],
			'email_promote_info' => email_promote_setting
			})
		render_json_auto true and return
	end

	def sms_promote
		sms_promote_setting = params[:sms_promote_setting]
		sms_promote_setting["promote_sms_count"] = @survey.sms_promote_info["promote_sms_count"]
		@survey.update_attributes({
			"sms_promotable" => params[:promotable],
			'sms_promote_info' => sms_promote_setting
			})
		render_json_auto true and return
	end

	def broswer_extension_promote
		@survey.update_attributes({
			"broswer_extension_promotable" => params[:promotable],
			'broswer_extension_promote_info' => params[:broswer_extension_promote_setting]
			})
		render_json_auto true and return
	end

	def weibo_promote
		@survey.update_attributes({
			"weibo_promotable" => params[:promotable],
			'weibo_promote_info' => params[:weibo_promote_setting]
			})
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

	def get_quillme_hot
		retval = { 'quillme_hot' => @survey.get_quillme_hot }
		render_json_auto retval and return
	end

	def set_quillme_hot
		render_json_auto @survey.set_quillme_hot(params[:quillme_hot]) and return
	end

	def allocate_answer_auditors
		retval = @survey.allocate_answer_auditors(params[:answer_auditor_ids], params[:allocate].to_s == "true")
		render_json_auto(retval) and return
	end

	def set_result_visible
		@survey.update_attributes({'publish_result' => (params[:visible].to_s == "true")})
		render_json_auto true and return
	end

	def get_result_visible
		render_json_auto @survey.publish_result and return
	end

	def set_spread
		retval = @survey.set_spread(params[:spread_point].to_i)
		render_json_auto(retval) and return
	end

	def get_spread
		@spread_info = {"spread_point" => @survey.spread_point}
		render_json_auto @spread_info and return
	end

	def destroy
		@survey = Survey.find_by_id(params[:id])
		# else just change status to -1
		render_json_auto @survey.try(:delete) and return
	end

	def list_sample_attributes_for_promote
		render_json_auto @survey.sample_attributes_for_promote and return
	end

	def add_sample_attribute_for_promote
		render_json_auto @survey.add_sample_attribute_for_promote(params[:sample_attribute]) and return
	end

	def update_sample_attribute_for_promote
		render_json_auto @survey.update_sample_attribute_for_promote(params[:sample_attribute_index], params[:sample_attribute]) and return
	end

	def remove_sample_attribute_for_promote
		render_json_auto @survey.remove_sample_attribute_for_promote(params[:sample_attribute_index]) and return
	end
end