# encoding: utf-8
# already tidied up

class Admin::AnnouncementsController < Admin::AdminController

  layout 'layouts/admin-todc'
  
  # GET
  def index
    @announcements = auto_paginate(PublicNotice.find_by_title(params[:title]).find_valid_notice) 
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

  def star
    render_json PublicNotice.where(:_id => params[:id]).first do |announcement|
      announcement.top = !(params[:star].to_s == 'true')
      announcement.save
      announcement.top
    end
  end  

  # POST
  def create
    @announcement = PublicNotice.create_public_notice({
          :public_notice_type => params[:announcement][:type].to_i,
          :title =>  params[:announcement][:title],
          :content =>  params[:announcement][:content]
        }, current_user)
    if @announcement.created_at
      redirect_to :action => :index
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
      redirect_to :action => :index
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