class RewardSchemesController < ApplicationController
	before_filter :require_sign_in

	def index
		retval = RewardScheme.where( :_id => params[:survey_id] )
	end

	def show

	end

	def create

	end

	def update

	end

	def destory

	end

end