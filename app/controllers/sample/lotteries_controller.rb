class Sample::LotteriesController < Sample::SampleController

	def initialize
		super('lottery')
	end

	def draw
		@answer = Answer.find_by_id(params[:id])
		render_json_e ErrorEnum::ANSWER_NOT_EXIST if @answer.nil?
		result = @answer.draw_lottery(current_user.try(:id))
		# client = Sample::LotteryClient.new(session_info)
		# result = client.draw(params[:id])

		if result.class == String && result.start_with?("error_")
			error_code = result
		else
			win = result["result"]
			prize_id = result["prize_id"] if win
			prize_title = result["prize_title"] if win
		end

=begin
		success     = result.value['result']
		prize_id    = result.value['prize_id'] if success 
		prize_title = result.value['prize_title'] if success
		error_code  = result.value['error_code'] if !success
=end

		draw_result = "#{params[:id]},#{win},#{error_code},#{prize_id},#{prize_title}"
		result_arr = (cookies[:draw_result] || '').split('_')
		result_arr << draw_result
		cookies[:draw_result] = {
   			:value => result_arr.join('_'),
   			:expires => Rails.application.config.answer_id_time_out_in_hours.hours.from_now,
   			:domain => :all
 		}		
		render_json_auto result and return
	end

	def show

		# client        = Sample::LotteryClient.new(session_info)

		@answer = Answer.find_by_id(params[:id])
		render_404 if @answer.nil?

		#获取该问卷下的抽奖奖品
		@lottery = @answer.find_lottery_answers
		# @lottery      = client.find_lottery_answers(params[:id])
		# @lottery      = @lottery.success ?  @lottery.value : nil

		#参与抽奖记录
		@fail_lottery_logs = LotteryLog.find_lottery_logs(params[:id],nil,8)
		# @fail_lottery_logs = client.get_lottery_logs(params[:id],nil,8)
		# @fail_lottery_logs = @fail_lottery_logs.success ? @fail_lottery_logs.value  : nil
		#中奖名单记录
		@succ_lottery_logs = LotteryLog.find_lottery_logs(params[:id],true,3)
		# @succ_lottery_logs = client.get_lottery_logs(params[:id],true,3)
		# @succ_lottery_logs = @succ_lottery_logs.success ? @succ_lottery_logs.value : nil

=begin
		#如果该答案不存在那么跳转到调研列表页
		if !@lottery.present?
			redirect_to surveys_path and return
		end
=end

		#获取参与人数
		@lottery_counts = LotteryLog.get_lottery_counts(@answer.survey.id)
		# @lottery_counts = client.get_lottery_counts(params[:id])
		# @lottery_counts = @lottery_counts.success ? @lottery_counts.value : nil		

		#判断该答案是否是会员创建
		sample_create = @lottery['user_id'].present? ? true : false

		if sample_create
			#如果是会员创建，当前访问用户没有登录，需要先登录,如果不是会员创建，不需要登录
			if !user_signed_in
				redirect_to sign_in_path(:ref => "#{request.protocol}#{request.host_with_port}#{request.fullpath}") and return 
			end

			#如果当前登录用户不是问卷的创建者，那么要无权参加抽奖
			if @lottery['user_id'] != current_user.try(:_id).to_s
				redirect_to "/s/#{@lottery['scheme_id']}" and return
			end			
		end


		status_arr = [Answer::UNDER_REVIEW, Answer::UNDER_AGENT_REVIEW, Answer::FINISH]
		if(!status_arr.include?(@lottery['status'].to_i))
			#判断该问卷是否已经答题完成，没有的话需要继续答题
			redirect_to "#{request.protocol}#{request.host_with_port}/a/#{params[:id]}" and return 
		end

		#获取当前登录用户的收获地址信息
		@receiver_info = current_user.nil? ? nil : current_user.affiliated.try(:receiver_info) || {}
		# @receiver_info =  Sample::UserClient.new(session_info).get_logistic_address
		# @receiver_info =  @recerver_info.success ? @recerver_info.value : nil	

		#记录抽奖状态，页面刷新时用

		(cookies[:draw_result] || '').split('_').each do |result|
			draw_result = result.split(',')
			answer_id = draw_result[0]
			if params[:id].to_s == answer_id.to_s
				@success   = draw_result[1]
				if @success.to_s == 'true'
					@prize_id    = draw_result[3]
					@prize_title = draw_result[4]
				else
					@error_code  =  draw_result[2]
				end
			end		
		end

		#获取登录用户的order_id
		@win_order = LotteryLog.get_order_by_answer_sample(params[:id])
		# @win_order       = client.get_lottery_order(params[:id])

		@win_order_id    = @win_order.present? ? @win_order.order_id  : nil
		@win_prize_id    = @win_order.present? ? @win_order.prize_id  : @prize_id	 
		@win_prize_title = @win_order.present? ? @win_order.prize_name  : @prize_title 

		@lottery_result  = @success
	end
end