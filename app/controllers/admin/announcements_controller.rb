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

  # POST
  def create
    params[:type] = params[:type].to_i
    if params[:attachment]
      photo = ImageUploader.new
      photo.store!(params[:attachment])
    end

    @announcement = PublicNotice.create_public_notice({
          :public_notice_type => params[:type].to_i,
          :title =>  params[:title],
          :content =>  params[:content],
          :attachment => photo.url.to_s
        }, current_user)

    if @announcement.updated_at
      redirect_to :action => :index
    else
      redirect_to :render => :new
    end
    # render :json => @result
  end

  # PUT
  def update
    @announcement = PublicNotice.find params[:id]
    
    photo = ImageUploader.new

    retval = @client._get({}, "/#{params[:id]}")
    photo.retrieve_from_store!(retval.value['attachment'].to_s.split('/').last)
    
    if params[:attachment]
      # del before
      # but not work!
      begin
        photo.remove!
      rescue Exception => e
        
      end
      # store new one
      photo.store!(params[:attachment])
    end

    if photo.url.to_s.strip != ""
      @result = @client._put({
        :public_notice => {
          :public_notice_type => params[:type].to_i,
          :title =>  params[:title],
          :content =>  params[:content],
          :attachment => photo.url.to_s
        }
      }, "/#{params[:id]}")
    else
      @result = @client._put({
        :public_notice => {
          :public_notice_type => params[:type].to_i,
          :title =>  params[:title],
          :content =>  params[:content]
        }
      }, "/#{params[:id]}")
    end

    if @result.success
      flash[:notice] ="更新成功!"
    else
      flash[:notice] = "更新失败!请重新更新,并保证完整性和标题唯一性!"
    end

    redirect_to request.url
  end

  # DELETE
  def destroy
    photo = ImageUploader.new
    retval = @client._get({}, "/#{params[:id]}")

    @result = @client._delete({}, "/#{params[:id]}")

    if @result.success
      photo.retrieve_from_store!(retval.value['attachment'].to_s.split('/').last)
      begin
        photo.remove!
      rescue Exception => e
        
      end
    end

    render :json => @result
  end

end