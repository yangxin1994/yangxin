# encoding: utf-8
# already tidied up

class Client::Sessions::ResetPasswordController < Client::ApplicationController
  

  before_filter :require_client, :only => [:index, :create]

  # PAGE: show sign in
  def index

  end

  def create
    if current_client.reset_password(params[:client][:password], params[:client][:new_password])
      flash[:success] = "密码修改成功!"
      render :index
    else
      flash[:success] = "密码修改失败!"
    end
  end

end
