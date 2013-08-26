class Admin::SamplesController < Admin::ApplicationController
	before_filter :check_sample_existence, :only => [:point_log, :redeem_log, :lottery_log, :answer_log, :spread_log, :show, :block, :set_sample_role, :operate_point]

	def check_sample_existence
		@sample = User.sample.find_by_id(params[:id])
		if @sample.nil?
			render_json_e(ErrorEnum::SAMPLE_NOT_EXIST) and return
		end
	end

	def index
		@samples = User.search_sample(params[:email], params[:mobile], params[:is_block].to_s == "true")
		render_json_auto(auto_paginate(@samples)) and return
	end

	def count
		@samples_count = User.count_sample(params[:period].to_s, params[:time_length].to_i)
		render_json_auto(@samples_count) and return
	end

	def active_count
		@active_samples_count = User.count_active_sample(params[:period], params[:time_length].to_i)
		render_json_auto(@active_samples_count) and return
	end

	def show
		render_json_auto(@sample.sample_attributes) and return
	end

	def send_message
		render_json_auto(@current_user.create_message(params[:title], params[:content], params[:sample_ids])) and return
	end

	def block
		render_json_auto(@sample.block(params[:block])) and return
	end

	def point_log
		@paginated_point_logs = auto_paginate(@sample.logs.point_logs) do |paginated_point_logs|
			paginated_point_logs.map { |e| e.info_for_admin }
		end
		render_json_auto(@paginated_point_logs) and return
	end

	def redeem_log
		@paginated_redeem_logs = auto_paginate(@sample.logs.redeem_logs) do |paginated_redeem_logs|
			paginated_redeem_logs.map { |e| e.info_for_admin }
		end
		render_json_auto(@paginated_redeem_logs) and return
	end

	def lottery_log
		@paginated_lottery_logs = auto_paginate(@sample.logs.lottery_logs) do |paginated_lottery_logs|
			paginated_lottery_logs .map { |e| e.info_for_admin }
		end
		render_json_auto(@paginated_lottery_logs) and return
	end

	def answer_log
		@paginated_answer_logs = auto_paginate(@sample.answers.not_preview.desc(:created_at)) do |paginated_answer_logs|
			paginated_answer_logs.map do |e|
				selected_reward = (e.rewards.select { |e| e["checked"] == true }).first
				reward_type = selected_reward.nil? ? 0 : selected_reward["type"]
				reward_amount = selected_reward.nil? ? 0 : selected_reward["amount"]
				{
					"_id" => e._id.to_s,
					"title" => e.survey.title,
					"created_at" => e.created_at,
					"finished_at" => e.finished_at.present? ? e.finished_at.to_i : nil,
					"status" => e.status,
					"reject_type" => e.reject_type,
					"reward_type" => reward_type,
					"reward_amount" => reward_amount
				}
			end
		end
		render_json_auto(@paginated_answer_logs) and return
	end

	def spread_log
		@paginated_spread_logs = auto_paginate(Answer.where(:introducer_id => @sample._id.to_s)) do |paginated_spread_logs|
			paginated_spread_logs.map do |e|
				{
					"_id" => e._id.to_s,
					"title" => e.survey.title,
					"created_at" => e.created_at,
					"finished_at" => e.finished_at.present? ? Time.at(e.finished_at.to_i) : nil,
					"email" => e.user.try(:email),
					"mobile" => e.user.try(:mobile),
					"status" => e.status,
					"reject_type" => e.reject_type
				}
			end
		end
		render_json_auto(@paginated_spread_logs) and return
	end

	def set_sample_role
		retval = @sample.set_sample_role(params[:role])
		render_json_auto(retval) and return
	end

	def operate_point
		retval = @sample.operate_point(params[:amount], params[:remark])
		render_json_auto retval and return
	end
end