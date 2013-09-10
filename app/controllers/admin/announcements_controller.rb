# encoding: utf-8

# coding: utf-8

class Admin::AnnouncementsController < Admin::AdminController

  layout 'layouts/admin-todc'
  
  # GET
  def index
    @announcements = auto_paginate(PublicNotice.find_valid_notice.find_by_title(params[:title])) 
  end

  # GET
  def show
    @announcement = PublicNotice.find params[:id]
  end

  def edit
    @announcement = PublicNotice.find params[:id]
  end

  def new
    @announcement ={}
  end

  # POST
  def create
    @announcement = PublicNotice.create_public_notice({
          :public_notice_type => params[:announcement][:type].to_i,
          :title =>  params[:announcement][:title],
          :content =>  params[:announcement][:content]
        }, current_user)
    if @announcement.created_at
      redirect_to :action => :index, :flash => {:success => "公告已成功发送."}
    else
      flash.alert = "公告创建失败,请检查参数!"
      render :new
    end
    # render :json => @result
  end

  # PUT
  def update
    @announcement = PublicNotice.find params[:id]
    @announcement.update_attributes(
        :public_notice_type => params[:announcement][:type].to_i,
        :title =>  params[:announcement][:title],
        :content =>  params[:announcement][:content])
    if @announcement.save
      redirect_to :action => :index, :flash => {:success => "公告已成功发送."}
    else
      flash.alert = "公告创建失败,请检查参数!"
      render :new
    end
  end

  # DELETE
  def destroy
    render_json PublicNotice.where(:_id => params[:id]).first do |public_notice|
      public_notice.destroy
    end
  end

end