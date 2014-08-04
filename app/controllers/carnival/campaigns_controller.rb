# encoding: utf-8
class Carnival::CampaignsController < Carnival::CarnivalController
  layout :resolve_layout
  #before_filter :force_tablet_html, :check_mobile_param
  
  #has_mobile_fu

  # Continue rendering HTML for tablet
  # def force_tablet_html
  #   session[:tablet_view] = false
  # end

  # def check_mobile_param
  #   force_mobile_format if params[:m].to_b
  # end

  def new_carnival(no_reward=false)
    @current_carnival_user = CarnivalUser.create_new(params[:i], params[:c],no_reward)
    set_carnival_user_cookie(@current_carnival_user.id.to_s)
  end


  def index
    @reward_list = CarnivalOrder.where(:type.in => [1,2])
  end

  def proxy
    redirect_to root_path and return 
    redirect_to carnival_campaigns_path  and return  if @current_carnival_user.present? && !@current_carnival_user.no_reward

    if params[:mob].present?
      carnival_user = CarnivalUser.where(mobile: params[:mob]).first
      if carnival_user.present?
        @current_carnival_user = carnival_user
        set_carnival_user_cookie(carnival_user.id.to_s)
      else
        new_carnival(true)
      end      
    else
      if @current_carnival_user.blank?
        new_carnival(true)
      end
    end

    pre_survey = Carnival::PRE_SURVEY

    if !@current_carnival_user.reward_scheme_order.nil?
      surveys = @current_carnival_user.reward_scheme_order
    end

    survey_status = @current_carnival_user.survey_status


    @answer_order = @current_carnival_user.survey_order.map do |e|
      a = @current_carnival_user.answers.where(survey_id: e).first
      a.present? ? a.id.to_s : ""
    end


    @prox_obj = {
      pre_survey:Carnival::PRE_SURVEY_REWARD_SCHEME,
      pre_status:@current_carnival_user.pre_survey_status,
      surveys:surveys,
      survey_status:@current_carnival_user.survey_status,
      mobile:@current_carnival_user.mobile,
      answer_orders:@answer_order,
      pre_reject_count: CarnivalUser.where(pre_survey_status: 2).length
    }
    return @prox_obj
  end

  private

  def resolve_layout
    case action_name
    when "proxy"
      "carnival_proxy"
    else
      "carnival"
    end
  end  


end
