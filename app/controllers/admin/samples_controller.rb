class Admin::SamplesController < Admin::ApplicationController
	before_filter :check_sample_attribute_existence, :only => [:point_log, :redeem_log, :lottery_log]

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
		render_json_auto(@sample.basic_info) and return
	end

	def send_message
		render_json_auto(@current_user.create_message(params[:title], params[:content], params[:sample_ids])) and return
	end

	def block
		render_json_auto(@sample.block(params[:block])) and return
	end

	def point_log
		render_json_auto(auto_paginate(@sample.point_logs)) and return
	end

	def redeem_log
		render_json_auto(auto_paginate(@sample.redeem_logs)) and return
	end

	def lottery_log
		render_json_auto(auto_paginate(@sample.lottery_logs)) and return
	end
end