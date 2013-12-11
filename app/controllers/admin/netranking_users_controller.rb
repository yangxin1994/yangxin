# encoding: utf-8
class Admin::NetrankingUsersController < ApplicationController

  layout "layouts/admin-todc"

  def index
    Rails.logger.info "AAAAAAAAAAA"
    Rails.logger.info params.inspect
    Rails.logger.info "AAAAAAAAAAA"

    @netranking_users = auto_paginate(NetrankingUser.all) if params[:search].blank?
    @netranking_users = auto_paginate(NetrankingUser.where(email: /#{params[:search]}/)) if params[:search].present?
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

  def import
    content = params[:file].read
    content.split("\n").each do |email|
      NetrankingUser.create(email: email) if NetrankingUser.where(email: email).first.nil?
    end
    flash[:notice] = "成功批量导入邮件"
    redirect_to action: :index
  end
end
