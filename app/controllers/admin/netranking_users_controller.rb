# encoding: utf-8
class Admin::NetrankingUsersController < ApplicationController

  layout "layouts/admin-todc"

  def index
    @netranking_users = NetrankingUser.all
  end

  def create
    if NetrankingUser.where(email: params[:email]).first.present?
      flash[:notice] = "邮箱已经存在"
      redirect_to action: :index and return
    end
    NetrankingUser.create(email: params[:email])
    flash[:notice] = "成功添加"
    redirect_to action: :index and return
  end

  def destroy
    render_json NetrankingUser.where(:_id => params[:id]).first do |user|
      user.destroy
    end
  end
end
