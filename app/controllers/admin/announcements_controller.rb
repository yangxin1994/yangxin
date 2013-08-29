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
    params[:type] = params[:type].to_i
    if params[:announcement][:attachment]
      photo = ImageUploader.new
      photo.store!(params[:announcement][:attachment])
    end

    @announcement = PublicNotice.create_public_notice({
          :public_notice_type => params[:announcement][:type].to_i,
          :title =>  params[:announcement][:title],
          :content =>  params[:announcement][:content],
          :attachment => photo.try('url')
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
    
    photo = ImageUploader.new

    photo.retrieve_from_store!(params[:announcement]['attachment'].to_s.split('/').last)
    
    if params[:attachment]
      # del before
      # but not work!
      begin
        photo.remove!
      rescue Exception => e
        
      end
      # store new one
      photo.store!(params[:announcement][:attachment])
    end

    if photo.url.to_s.strip != ""
      @announcement.update_attributes(
          :public_notice_type => params[:announcement][:type].to_i,
          :title =>  params[:announcement][:title],
          :content =>  params[:announcement][:content],
          :attachment => photo.try('url'))
    else
      @announcement.update_attributes(
          :public_notice_type => params[:announcement][:type].to_i,
          :title =>  params[:announcement][:title],
          :content =>  params[:announcement][:content])
    end
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