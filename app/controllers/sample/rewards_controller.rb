class Sample::RewardsController < Sample::SampleController

	before_filter :require_sign_in

	def initialize
		super('reward')
	end

	def index
		@total_point = Account::UserClient.new(session_info).point
		@total_point.success ? @total_point = @total_point.value : @total_point = -1

		@point_logs = Sample::RewardLogClient.new(session_info).point_logs(params[:page].to_i, 20)
		@point_logs.success ? @point_logs = @point_logs.value : @point_logs = nil
		# render json: @point_logs
	end

end