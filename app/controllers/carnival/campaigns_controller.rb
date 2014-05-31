# encoding: utf-8
class Carnival::CampaignsController < Carnival::CarnivalController
  def index
    if @current_carnival_user.blank?
      @current_carnival_user = CarnivalUser.create_new(params[:i], params[:c])
      set_carnival_user_cookie(@current_carnival_user.id.to_s)
    end

    Rails.logger.info('--------------------------------------')
    Rails.logger.info(@current_carnival_user.inspect)
    Rails.logger.info('--------------------------------------')

    pre_survey = Carnival::PRE_SURVEY

    background_survey = Carnival::BACKGROUND_SURVEY

    #surveys = Carnival::SURVEY.each_slice(5).to_a

    if !@current_carnival_user.reward_scheme_order.nil?
      surveys = @current_carnival_user.reward_scheme_order.each_slice(5).to_a
    else
      surveys = [[122,133,144,155,166],[222,233,244,255,266], [322,333,344,355]]
    end

    step_arr = @current_carnival_user.survey_status.each_slice(5).to_a

    step = 0

    if (step_arr[2].include?(CarnivalUser::UNDER_REVIEW) || step_arr[2].include?(CarnivalUser::UNDER_REVIEW) || step_arr[2].include?(CarnivalUser::FINISH) )
      step = 3
    elsif (step_arr[1].include?(CarnivalUser::UNDER_REVIEW) || step_arr[1].include?(CarnivalUser::UNDER_REVIEW) || step_arr[1].include?(CarnivalUser::FINISH) )  
      step = 2
    elsif (step_arr[0].include?(CarnivalUser::UNDER_REVIEW) || step_arr[0].include?(CarnivalUser::UNDER_REVIEW) || step_arr[0].include?(CarnivalUser::FINISH) )
      step = 1
    end

    if @current_carnival_user.carnival_orders.present?
      @priz_name = @current_carnival_user.carnival_orders.last.carnival_prize.try(:name)  
    end
    

    @obj = {
      pre_status:@current_carnival_user.pre_survey_status,
      step:step,
      pre_survey:Carnival::PRE_SURVEY_REWARD_SCHEME,
      background_survey:Carnival::BACKGROUND_SURVEY_REWARD_SCHEME,
      background_survey_status:@current_carnival_user.background_survey_status,
      t1_surveys:surveys[0],
      t2_surveys:surveys[1],
      t3_surveys:surveys[2],
      t1_status:step_arr[0],
      t2_status:step_arr[1],
      t3_status:step_arr[2],
      priz_1:CarnivalPrize.where(name: "红米note").first.name,
      priz_2:CarnivalPrize.where(name: "小米盒子").first.name,
      priz_3:CarnivalPrize.where(name: "小米移动电源").first.name,
      pre_reject_count: CarnivalUser.where(pre_survey_status: 2).length,
      share_num:@current_carnival_user.share_num,
      share_lottery_num:@current_carnival_user.share_lottery_num,
      own:@current_carnival_user.carnival_orders.where(:type.in => [CarnivalOrder::STAGE_3_LOTTERY, CarnivalOrder::SHARE]).present?,
      prize_name:@priz_name
    }

    return @obj 
  end

end
