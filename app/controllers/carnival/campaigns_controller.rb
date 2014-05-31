class Carnival::CampaignsController < Carnival::CarnivalController
  def index
    if @current_carnival_user.blank?
      @current_carnival_user = CarnivalUser.create_new(params[:i], params[:c])
      set_carnival_user_cookie(@current_carnival_user.id.to_s)
    end

    Rails.logger.info('-----------------------------')
    Rails.logger.info(@current_carnival_user.inspect)
    Rails.logger.info('-----------------------------')
    pre_survey = Carnival::PRE_SURVEY

    background_survey = Carnival::BACKGROUND_SURVEY

    surveys = Carnival::SURVEY.each_slice(5).to_a

    step_arr = @current_carnival_user.survey_status.each_slice(5).to_a

    step = 0

    if (step_arr[2].include?(CarnivalUser::UNDER_REVIEW) || step_arr[2].include?(CarnivalUser::UNDER_REVIEW) || step_arr[2].include?(CarnivalUser::FINISH) )
      step = 3
    elsif (step_arr[1].include?(CarnivalUser::UNDER_REVIEW) || step_arr[1].include?(CarnivalUser::UNDER_REVIEW) || step_arr[1].include?(CarnivalUser::FINISH) )  
      step = 2
    elsif (step_arr[0].include?(CarnivalUser::UNDER_REVIEW) || step_arr[0].include?(CarnivalUser::UNDER_REVIEW) || step_arr[0].include?(CarnivalUser::FINISH) )
      step = 1
    end

    @obj = {
      pre_status:@current_carnival_user.pre_survey_status,
      step:step,
      pre_survey:pre_survey,
      background_survey:background_survey,
      background_survey_status:@current_carnival_user.background_survey_status,
      t1_surveys:surveys[0],
      t2_surveys:surveys[1],
      t3_surveys:surveys[2],
      t1_status:step_arr[0],
      t2_status:step_arr[1],
      t3_status:step_arr[2],
      pre_reject_count: CarnivalUser.where(pre_survey_status: 2).length
    }

    return @obj 
  end

end
