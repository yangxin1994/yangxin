# encoding: utf-8
class Carnival::CampaignsController < Carnival::CarnivalController
  def index
    if @current_carnival_user.blank?
      @current_carnival_user = CarnivalUser.create_new(params[:i], params[:c])
      set_carnival_user_cookie(@current_carnival_user.id.to_s)
    end

    pre_survey = Carnival::PRE_SURVEY

    background_survey = Carnival::BACKGROUND_SURVEY

    if !@current_carnival_user.reward_scheme_order.nil?
      surveys = @current_carnival_user.reward_scheme_order.each_slice(5).to_a
    end

    step_arr = @current_carnival_user.survey_status.each_slice(5).to_a

    #是否领取了第一关10元话费充值
    @rew_1 = @current_carnival_user.carnival_orders.where(:type.in => [CarnivalOrder::STAGE_1]).first

    step = 0

    #如果预调研通过,则进入第一关
    if @current_carnival_user.pre_survey_status.to_i == 32
      step = 1
    end

    #如果领取了第一关的话费奖励,则进入到第二关
    if @rew_1.present?
      step = 2
    end

    #如果第二关已经抽奖,则进入到第三关
    if @current_carnival_user.lottery_status[0] > 0
      step = 3
    end

    # step = 0
    # #根据status的的数据情况来判断是第几关
    # if (step_arr[2].include?(CarnivalUser::UNDER_REVIEW) || step_arr[2].include?(CarnivalUser::HIDE) || step_arr[2].include?(CarnivalUser::FINISH) )
    #   step = 3
    # elsif (step_arr[1].include?(CarnivalUser::UNDER_REVIEW) || step_arr[1].include?(CarnivalUser::HIDE) || step_arr[1].include?(CarnivalUser::FINISH) )  
    #   step = 2
    # elsif (step_arr[0].include?(CarnivalUser::UNDER_REVIEW) || step_arr[0].include?(CarnivalUser::HIDE) || step_arr[0].include?(CarnivalUser::FINISH) )
    #   step = 1
    # end

    #抽中大奖的奖品名称
    @lot = @current_carnival_user.carnival_orders.where(:type.in => [CarnivalOrder::STAGE_3_LOTTERY, CarnivalOrder::SHARE]).first 
    if @lot.present?
      @priz_name = @lot.carnival_prize.name  
    end
    


    #三种话费的抽奖 
    #lottery_status
    #第一个元素代表话费的抽奖,1表示已经抽过奖,0表示没有抽过奖
    #第二个元素代表抽大奖,1表示已经抽过,0表示没有抽过
    @rew_2_name = nil;
    if @current_carnival_user.lottery_status[0] > 0
      phone_lot = @current_carnival_user.carnival_orders.where(:type => CarnivalOrder::STAGE_2).first
      if phone_lot.present?
        @rew_2_name = phone_lot.amount
      end
    end

    #第三关 话费充值订单及名称
    @rew_3 = @current_carnival_user.carnival_orders.where(:type.in => [CarnivalOrder::STAGE_3]).first
    if @rew_3.present?
      @rew_3_name = @rew_3.amount
    end

    @charged_amount = [
      @current_carnival_user.carnival_orders.where(type: CarnivalOrder::STAGE_1).first.try(:charged).to_i,
      @current_carnival_user.carnival_orders.where(type: CarnivalOrder::STAGE_2).first.try(:charged).to_i,
      @current_carnival_user.carnival_orders.where(type: CarnivalOrder::STAGE_3).first.try(:charged).to_i,
    ]



    @obj = {
      pre_status:@current_carnival_user.pre_survey_status,
      step:step,
      pre_survey:Carnival::PRE_SURVEY_REWARD_SCHEME,
      background_survey:Carnival::BACKGROUND_SURVEY_REWARD_SCHEME,
      background_survey_status:@current_carnival_user.background_survey_status,
      t1_surveys:surveys[0],#第一关的五个问卷scheme_id
      t2_surveys:surveys[1],#第二关的五个问卷scheme_id
      t3_surveys:surveys[2],#第三关的五个问卷scheme_id
      t1_status:step_arr[0],#第一关的五个问卷的答题状态
      t2_status:step_arr[1],#第二关的五个问卷的答题状态
      t3_status:step_arr[2],#第三关的五个问卷的答题状态
      priz_1:CarnivalPrize.where(name: "红米note").first.name,
      priz_2:CarnivalPrize.where(name: "小米盒子").first.name,
      priz_3:CarnivalPrize.where(name: "小米移动电源").first.name,
      pre_reject_count: CarnivalUser.where(pre_survey_status: 2).length,#预调研已经拒绝的人数
      share_num:@current_carnival_user.share_num,#可抽大奖的总次数
      share_lottery_num:@current_carnival_user.share_lottery_num,#已经抽大奖的次数
      own:@lot.present?,#是否有抽中大奖
      prize_name:@priz_name,#抽中大奖的名称
      #是否领取了第一关的10块钱充值
      rew_1:@rew_1.present?,
      rew_2_name:@rew_2_name,#三种话费抽奖,如果抽中，抽中的面值
      rew_3:@rew_3.present?,#是否领取了第三关的10块钱充值
      rew_3_name:@rew_3_name,#第三关的充值面额
      #第一个元素代表话费的抽奖,1表示已经抽过奖,0表示没有抽过奖
      #第二个元素代表抽大奖,1表示已经抽过,0表示没有抽过
      lot_status:@current_carnival_user.lottery_status, 
      mobile:@current_carnival_user.mobile, #手机号
      charged_amount: @charged_amount
    }

    return @obj 
  end

end
