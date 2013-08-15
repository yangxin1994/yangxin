class Sample::LotteriesController < Sample::SampleController

	#before_filter :require_sign_in, :except => [:index, :show]

	def initialize
		super('lottery')
	end


	def draw
		client = Sample::LotteryClient.new(session_info)
		result = client.draw(params[:id])
		success = result.value['result']
		if success
			session['win_prize_id']    = result.value['prize_id']
			session['win_prize_title'] =  result.value['prize_title']
		end
		render json: result
	end



	def show
		client        = Sample::LotteryClient.new(session_info)
		@fail_lottery_logs = client.get_lottery_logs(params[:id],nil,8)
		@fail_lottery_logs = @fail_lottery_logs.success ? @fail_lottery_logs.value  : nil		
		Rails.logger.info("--------------------------")
		@fail_lottery_logs.each do |log|
				Rails.logger.info(log.inspect)
		end
		Rails.logger.info("--------------------------")
		@succ_lottery_logs = client.get_lottery_logs(params[:id],true,3)
		@succ_lottery_logs = @succ_lottery_logs.success ? @succ_lottery_logs.value : nil
		Rails.logger.info("!!!!!!!!!!!!!!!!!!!!!!!!!!!")
		@succ_lottery_logs.each do |log|
				Rails.logger.info(log.inspect)
		end		
		Rails.logger.info("!!!!!!!!!!!!!!!!!!!!!!!!!!!")
		@lottery      = client.find_lottery_answers(params[:id])
		@lottery      = @lottery.success ?  @lottery.value : nil
	  	@recerver_info =  Sample::UserClient.new(session_info).get_logistic_address
	  	@recerver_info =  @recerver_info.success ? @recerver_info.value : nil	
	  	@lottery_counts = client.get_lottery_counts(params[:id])
	  	@lottery_counts = @lottery_counts.success ? @lottery_counts.value : nil

	end
	
end