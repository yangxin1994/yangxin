require 'error_enum'

class Admin::RewardSchemesController < Admin::ApplicationController
	before_filter :check_survey_existence

	def check_survey_existence
		@survey = Survey.find_by_id(params[:survey_id])
		render_json_auto(ErrorEnum::SURVEY_NOT_EXIST) and return if @survey.nil?
	end

	def index
		reward_schemes = @survey.reward_schemes
		render_json_auto( auto_paginate(reward_schemes) )  and return
	end

	def show
		reward_scheme = RewardScheme.find_by_id(params[:id])
		retval = (reward_scheme.nil? ? ErrorEnum::REWARD_SCHEME_NOT_EXIST : reward_scheme)
		render_json_auto(retval)
	end

	def create
		retval = RewardScheme.create_reward_scheme(@survey, params[:reward_scheme_setting])
		render_json_auto(retval) and return
	end

	def update
		retval = RewardScheme.update_reward_scheme(params[:id], params[:reward_scheme_setting])
		render_json_auto(retval) and return
	end
end