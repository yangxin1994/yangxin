require 'error_enum'
class BrowsersController < ApplicationController
	before_filter :check_extension_version
	before_filter :check_browser_existence, :except => [:create]

	def check_extension_version
		@be = BrowserExtension.find_by_type(params[:browser_extension_type])
		render_json_e(ErrorEnum::BROWSER_EXTENSION_NOT_EXIST) and return if @be.nil?
	end

	def check_browser_existence
		@browser = Browser.find_by_id(params[:id])
		render_json_e(ErrorEnum::BROWSER_NOT_EXIST) and return if @browser.nil?
		@browser.update_attributes(:last_request_time => Time.now.to_i)
	end

	def create
		browser = Browser.create
		browser.browser_extension = @be
		browser.save
		render_json_s(browser._id.to_s) and return
	end

	def update_history
		# update the history
		retval = @browser.update_history(params[:browser_history_array])
		if retval == true
			render_json_auto({:version => @be.version}) and return
		else
			render_json_auto(retval) and return
		end
	end

	def get_recommended_surveys
		# obtain the recomended surveys
		survey_ids_answered = @current_user.try(:get_survey_ids_answered) || []
		exclude_survey_ids = ((params[:exclude_survey_ids] || []) + survey_ids_answered).uniq
		surveys_with_reward = @browser.recommend_surveys_with_reward(exclude_survey_ids)
		surveys_without_reward = @browser.recommend_surveys_without_reward(exclude_survey_ids)
		retval = {
			:version => @be.version,
			:recommended_surveys => [
				surveys_without_reward,
				surveys_with_reward[:point],
				surveys_with_reward[:lottery]],
			:url_surveys => SurveyRecommendation.url_recommendations(exclude_survey_ids),
			:key_word_surveys => SurveyRecommendation.key_word_recommendations(exclude_survey_ids)}
		render_json_s(retval) and return
	end

	def get_survey_info
		survey = Survey.normal.find_by_id(params[:survey_id])
		render_json_e(ErrorEnum::SURVEY_NOT_EXIST) and return if survey.nil?
		render_json_auto(survey.serialize_in_short) and return
	end
end
