require 'error_enum'

class Sample::RewardSchemesController < ApplicationController
	def show
		reward_scheme = RewardScheme.find_by_id(params[:id])
		retval = (reward_scheme.nil? ? ErrorEnum::REWARD_SCHEME_NOT_EXIST : reward_scheme)
		render_json_auto(retval)
	end
end