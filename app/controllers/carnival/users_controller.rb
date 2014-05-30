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

  def draw_lottery
    
  end
end
