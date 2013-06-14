require 'error_enum'

class RewardSchemesController < ApplicationController
	before_filter :require_sign_in

	def index
		reward_scheme = Survey.reward_schemes   ##Return a Array, [] means find nothing
		render_json_auto( auto_paginate(result) )  and return
	end

	def show
		reward_scheme = RewardScheme.find_by_id(:id)
		render_json_auto(reward_scheme)
	end

	def create
		retval = RewardScheme.create_reward_scheme(params[:reward_scheme_id], params[:reward_scheme_setting])
		render_json_auto(retval) and return
	end

	def update
		retval = RewardScheme.update_review_scheme(params[:reward_scheme_id], params[:reward_scheme_setting])
		format.json	{ render_json_auto(retval) and return }
	end

	def destory
		reward_scheme = RewardScheme.find_by_id(params[:id])
		retval = (reward_scheme == nil ? ErrorEnum::REWARD_SCHEME_NOT_EXIST : reward_scheme.destory)
		render_json_auto(retval) and return
	end

end