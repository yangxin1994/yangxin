# already refaoring
class Sample::LotteriesController < Sample::SampleController

  def draw
    @answer = Answer.find_by_id(params[:id])
    render_json_e ErrorEnum::ANSWER_NOT_EXIST if @answer.nil?
    result = @answer.draw_lottery(current_user.try(:id))

    error_code = result if result.class == String && result.start_with?("error_")
    win = result["result"]
    prize_id = result["prize_id"] and  prize_title = result["prize_title"]  if win
    
    cookies[params[:id]] = {
      :value => {win:win,prize_id:prize_id,prize_title:prize_title,error_code:error_code},
      :expires => Rails.application.config.answer_id_time_out_in_hours.hours.from_now,
      :domain => :all
    }
    render_json_auto result and return
  end

  def show
    @answer = Answer.find_by_id(params[:id])
    render_404 if @answer.nil?
    #参与抽奖记录
    @lottery_logs = LotteryLog.find_lottery_logs(params[:id],nil,8)
    #中奖名单记录
    @succ_lottery_logs = LotteryLog.find_lottery_logs(params[:id],true,3)
    #判断该答案是否是会员创建
    if @answer.user_id.present?
      #如果是会员创建，当前访问用户没有登录，需要先登录,如果不是会员创建，不需要登录
      redirect_to sign_in_path(:ref => "#{request.protocol}#{request.host_with_port}#{request.fullpath}") and return   unless user_signed_in
      #如果当前登录用户不是问卷的创建者，那么要无权参加抽奖
      redirect_to "/s/#{@answer.survey.scheme_id}" and return  if @answer.user_id.to_s != current_user.try(:_id).to_s
    end

    status_arr = [Answer::UNDER_REVIEW, Answer::UNDER_AGENT_REVIEW, Answer::FINISH]
    if(!status_arr.include?(@answer.status.to_i))
      #判断该问卷是否已经答题完成，没有的话需要继续答题
      redirect_to "#{request.protocol}#{request.host_with_port}/a/#{params[:id]}" and return 
    end

    #获取该问卷下的抽奖奖品
    @prizes = Prize.where(:id.in => @answer.rewards.first['prizes'].map{|p| p['id']})
    #获取当前登录用户的收获地址信息
    @receiver_info = current_user.nil? ? nil : current_user.affiliated.try(:receiver_info) || {}
    #记录抽奖状态，页面刷新时用
    draw_history = eval(cookies[params[:id]]) if cookies[params[:id]].present?
    if draw_history.present?
      @success     = draw_history[:win]
      @prize_id    = draw_history[:prize_id]
      @prize_title = draw_history[:prize_title]
      @error_code  = draw_history[:error_code]
    end

    #获取登录用户的order_id
    @win_order = LotteryLog.get_order_by_answer_sample(params[:id])
    @win_order_id    = @win_order.present? ? @win_order.order_id  : nil
    @win_prize_id    = @win_order.present? ? @win_order.prize_id  : @prize_id  
    @win_prize_title = @win_order.present? ? @win_order.prize_name  : @prize_title 
    @lottery_result  = @success
  end
end