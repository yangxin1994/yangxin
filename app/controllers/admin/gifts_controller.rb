class Admin::GiftsController < Admin::AdminController

  layout "layouts/admin-todc"

  def index
    @gifts = auto_paginate Gift.search_gift(params[:title], params[:status].to_i, params[:type].to_i)
  end

  def show
    #render :json => @gift_client.show(params[:id])
    @gift = Gift.find(params[:id])
    @gift['photo_url'] = @gift.photo.try 'value'
  end

  def new
    @gift = {}
  end

  def create
    photo = ImageUploader.new
    photo.store!(params[:gift][:photo])

    params[:gift].delete(:photo)
    params[:gift][:photo_url] = photo.url

    @gift = Gift.create(params[:gift])
    @gift.update_gift(params[:gift])
    if @gift.created_at
      redirect_to admin_gifts_path
    else
      render :new
    end
  end

  def edit
    @gift = Gift.find(params[:id])
    @gift['photo_url'] = @gift.photo.try 'value'
  end

  def update
    if params[:gift][:photo]
      photo = ImageUploader.new
      photo.store!(params[:gift][:photo])
      params[:gift].delete(:photo)
      params[:gift][:photo_url] = photo.url
    end
    @gift = Gift.find params[:id]
    @gift.update_gift(params[:gift])
    redirect_to edit_admin_gift_path(params[:id])
  end

  def destroy
    render_json @gift = Gift.where(:_id =>params[:id]).first do |gift|
      success_true gift.destroy
    end
  end

  def outstock
    render_json @gift = Gift.where(:_id =>params[:id]).first do |gift|
      success_true gift.update_attributes(:status => 2)
    end
  end

  def stockup
    render_json @gift = Gift.where(:_id =>params[:id]).first do |gift|
      success_true gift.update_attributes(:status => 1)
    end
  end

end
