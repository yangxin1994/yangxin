# encoding: utf-8
class Admin::InterviewersController < Admin::AdminController

  layout "layouts/admin-todc"

  def index
    if params[:keyword].present?
      @interviewers = auto_paginate User.where(email: /#{params[:keyword]}/, interviewer: true) do |interviewers|
        interviewers
      end
    else
      @interviewers = auto_paginate User.where(interviewer: true) do |interviewers|
        interviewers
      end
    end
  end


  def new
    @interviewer = {}
  end

  def create
    @interviewer = User.find_by_email(params[:interviewer]["email"])
    if @interviewer.present?
      @interviewer = {}
      flash.alert = "邮箱已经存在，访问员创建失败"
      render :new and return
    end
    @interviewer = User.create(email: params[:interviewer]["email"],
      user_role: 17,
      interviewer: true,
      status: 2,
      email_activation: true,
      last_login_time: Time.now.to_i)
    @interviewer.password = Encryption.encrypt_password(params[:interviewer]["password"])
    @interviewer.save
    @interviewer.write_sample_attribute("nickname", params[:interviewer]["name"])
    redirect_to admin_interviewers_path, :flash => {:success => "访问员创建成功!"} and return
  end

  def edit
    @interviewer = User.find(params[:id])
    @interviewer["name"] = @interviewer.read_sample_attribute("nickname")
  end

  def update
    @interviewer = User.find(params[:id])
    if @interviewer.nil?
      redirect_to admin_interviewers_path, :flash => {:alert => "访问员更新失败!"} and return
    end
    u = User.find_by_email(params[:interviewer]["email"])
    if u.present? && u != @interviewer
      redirect_to edit_admin_interviewer_path(@interviewer), :flash => {:alert => "邮箱已存在，访问员更新失败!"} and return
    end
    @interviewer.email = params[:interviewer]["email"]
    @interviewer.save
    @interviewer.write_sample_attribute("nickname", params[:interviewer]["name"])
    if params["interviewer"]["password"].present?
      @interviewer.password = Encryption.encrypt_password(params[:interviewer]["password"])
      @interviewer.save
    end
    redirect_to admin_interviewers_path, :flash => {:success => "访问员更新成功!"}
  end
end
