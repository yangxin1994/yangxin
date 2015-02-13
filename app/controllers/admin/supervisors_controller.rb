# encoding: utf-8
class Admin::SupervisorsController < Admin::AdminController

  layout "layouts/admin-todc"

  def index
    if params[:keyword].present?
      @supervisors = auto_paginate User.where(email: /#{params[:keyword]}/, supervisor: true) do |supervisor|
        supervisor
      end
    else
      @supervisors = auto_paginate User.where(supervisor: true) do |supervisor|
        supervisor
      end
    end
  end


  def new
    @supervisor = {}
  end

  def create
    @supervisor = User.find_by_email(params[:supervisor]["email"])
    if @supervisor.present?
      @supervisor = {}
      flash.alert = "邮箱已经存在，监督员创建失败"
      render :new and return
    end
    @supervisor = User.create(email: params[:supervisor]["email"],
      user_role: 32,
      supervisor: true,
      status: 2,
      email_activation: true,
      last_login_time: Time.now.to_i)
    @supervisor.password = Encryption.encrypt_password(params[:supervisor]["password"])
    @supervisor.save
    @supervisor.write_sample_attribute("nickname", params[:supervisor]["name"])
    redirect_to admin_supervisors_path, :flash => {:success => "监督员创建成功!"} and return
  end

  def edit
    @supervisor = User.find(params[:id])
    @supervisor["name"] = @supervisor.read_sample_attribute("nickname")
  end

  def update
    @supervisor = User.find(params[:id])
    if @supervisor.nil?
      redirect_to admin_supervisors_path, :flash => {:alert => "监督员更新失败!"} and return
    end
    u = User.find_by_email(params[:supervisor]["email"])
    if u.present? && u != @supervisor
      redirect_to edit_admin_supervisor_path(@supervisor), :flash => {:alert => "邮箱已存在，监督员更新失败!"} and return
    end
    @supervisor.email = params[:supervisor]["email"]
    @supervisor.save
    @supervisor.write_sample_attribute("nickname", params[:supervisor]["name"])
    if params["supervisor"]["supervisor"].present?
      @supervisor.password = Encryption.encrypt_password(params[:supervisor]["password"])
      @supervisor.save
    end
    redirect_to admin_supervisors_path, :flash => {:success => "监督员更新成功!"}
  end
end
