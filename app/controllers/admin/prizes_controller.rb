# already tidied up
class Admin::PrizesController < Admin::AdminController
  before_filter :require_sign_in, :only => [:index, :create, :update, :destroy]

  layout "layouts/admin-todc"

  def index
    @prizes = auto_paginate Prize.search_prize(params[:keyword], params[:type].to_i)
  end

  def new
    @prize = {}
  end

  def show
    @prize = Prize.find(params[:id])
  end

  def edit
    @prize = Prize.find(params[:id])
  end

  def create
    photo = ImageUploader.new
    photo.store!(params[:prize][:photo])

    params[:prize].delete(:photo)
    params[:prize][:photo_url] = photo.url

    
    if @prize = Prize.create_prize(params[:prize])
      redirect_to admin_prizes_path
    else
      render :new
    end
  end

  def update
    @prize = Prize.find(params[:id])
    if params[:prize][:photo]
      photo = ImageUploader.new
      photo.store!(params[:prize][:photo])

      params[:prize].delete(:photo)
      params[:prize][:photo_url] = photo.url
    end
    if @prize.update_prize(params[:prize])
      redirect_to admin_prizes_path
    else
      @prize = params[:prize]
      render :edit
    end
  end

  def destroy
    render_json @prize = Prize.where(:_id =>params[:id]).first do |prize|
      success_true prize.delete_prize
    end
  end
  
end
