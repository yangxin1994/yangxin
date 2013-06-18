class Admin::SampleController < Admin::ApplicationController
	before_filter :check_sample_attribute_existence, :only => []

	def check_sample_attribute_existence
		@sample_attribute = SampleAttribute.normal.find_by_id(params[:id])
		if @sample_attribute.nil?
			render_json_e(ErrorEnum::SAMPLE_ATTRIBUTE_NOT_EXIST) and return
		end
	end

	def index
		@samples = User.search_sample(params[:email], params[:mobile], params[:is_block])
		render_json_auto(auto_paginate(@samples)) and return
	end

	def count
		@samples_count = User.count_sample(params[:period].to_s, params[:time_length].to_i)
		render_json_auto(@samples_count) and return
	end

	def active_count
		@active_samples_count = User.count_active_sample(params[:period], params[:time_length])
		render_json_auto(@active_samples_count) and return
	end

	def show
		
	end

	def send_message
		
	end

	def block
		
	end

	def point_log
		
	end

	def redeem_log
		
	end

	def lottery_log
		
	end
end