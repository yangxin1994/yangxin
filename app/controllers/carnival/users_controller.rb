# already tidied up
class Carnival::UsersController < Carnival::CarnivalController

  def update
    carnival_user = CarnivalUser.find(cookies[:carnival_user_id])
    carnival_user.mobile = params[:mobile]
    carnival_user.save
  end

  def login
    carnival_user = CarnivalUser.where(mobile: params[:mobile]).first
    if carnival_user.present?
      set_carnival_user_cookie(carnival_user.id.to_s)
      render_json_auto true and return
    else
      render_json_auto false and return
    end
  end

  # parameters:
  # => type: 0代表第二个大任务的抽奖，1代表第三个大任务的抽奖，2代表分享成功的抽奖，3代表第一个大任务的10元充值卡，4代表第三个大任务的10充值卡
  # => amount: type为0时有意义，可以为10, 50或者100，为充值卡面值
  # => mobile: 
  def draw_lottery
    if current_carnival_user.blank?
      render_json_auto CarnivalUser::USER_NOT_EXIST and return
    end
    if current_carnival_user.background_survey_status != CarnivalUser::FINISH
      render_json_auto CarnivalUser::BACKGROUND_SURVEY_NOT_FINISHED and return
    end
    case params[:type].to_i
    when 0
      retval = current_carnival_user.draw_second_stage_lottery(params[:amount].to_i)
    when 1
      retval = current_carnival_user.draw_third_stage_lottery
    when 2
      retval = current_carnival_user.draw_share_lottery
    when 3
      retval = current_carnival_user.create_first_stage_order(params[:mobile])
    when 4
      retval = current_carnival_user.create_third_stage_mobile_order
    end
    render_json_auto retval and return
  end

  def send_mobile
    render_json_auto CarnivalUser::MOBILE_NOT_PRESENT and return  unless params[:mobile].present?
    mobile = CarnivalUser.where(mobile:params[:mobile]).first
    render_json_auto CarnivalUser::MOBILE_EXIST and return if mobile.present?
    render_json_auto current_carnival_user.update_attributes(mobile:params[:mobile])
  end
end
