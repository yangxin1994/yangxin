# already tidied up
class Carnival::UsersController < Carnival::CarnivalController

  def update
    carnival_user = CarnivalUser.find(params[:id])
    carnival_user.email = params[:email]
    carnival_user.save
  end

  def login
    carnival_user = CarnivalUser.where(email: params[:email]).first
    if carnival_user.present?
      cookies[:carnival_user_id] = carnival_user.id.to_s
      render_json_auto true and return
    else
      render_json_auto false and return
    end
  end

  # parameters:
  # => type: 0代表第二个大任务的抽奖，1代表第三个大任务的抽奖，2代表分享成功的抽奖，3代表第一个大任务的10元充值卡，4代表第三个大任务的10充值卡
  # => amount: type为0时有意义，可以为20或者50，为充值卡面值
  def draw_lottery
    if current_carnival_user.blank?
      render_json_auto -1 and return
    end
    case param[:type].to_i
    when 0
      current_carnival_user.draw_second_stage_lottery(param[:amount].to_i)
    when 1
      current_carnival_user.draw_third_stage_lottery
    when 2
      current_carnival_user.draw_share_lottery
    when 3
      current_carnival_user.create_first_stage_order
    when 4
      current_carnival_user.create_third_stage_mobile_order
    end
  end
end
