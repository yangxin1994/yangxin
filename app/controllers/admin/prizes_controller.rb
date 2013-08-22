#encoding: utf-8

class Admin::PrizesController < Admin::AdminController
  before_filter :require_sign_in, :only => [:index, :create, :update, :destroy]

  before_filter :get_prizes_client

  layout "layouts/admin-todc"

  def get_prizes_client
    @prizes_client = Admin::PrizeClient.new(session_info)
  end

  def index
    @search_title = params[:title]
    @search_type = params[:type] if params[:type]
    result = @prizes_client.index(page, per_page, @search_title, @search_type)
    if result.success
      @prizes = result.value
      if params[:partial]
        render :partial => "prizes"
      end
    else
      render :json => result
    end
  end

  def new
    @prize = {}
  end

  def show
    @prize = @prizes_client.show(params[:id])
    respond_to do |format|
      format.html do
        render :layout => false
      end
      format.json do
        render :json => @prize
      end
    end
  end

  def edit
    @prize = @prizes_client.show(params[:id])
    if @prize.success
      @prize = @prize.value
    else
      render :json => @prize
    end
  end

  def create
    photo = ImageUploader.new
    photo.store!(params[:prize][:photo])

    params[:prize].delete(:photo)
    params[:prize][:photo_url] = photo.url

    @prize = @prizes_client.create(params[:prize])
    if @prize.success
      flash[:success] = "奖品被成功创建了~"
      redirect_to admin_prizes_path
    else
      flash.now[:failure] = "是不是填错了什么信息?再检查一遍吧"
      @prize = @prize.value
      render :new
    end
  end

  def update
    if params[:prize][:photo]
      photo = ImageUploader.new
      photo.store!(params[:prize][:photo])

      params[:prize].delete(:photo)
      params[:prize][:photo_url] = photo.url
    end

    @prize = @prizes_client.update(params[:id], params[:prize])
    if @prize.success
      redirect_to admin_prizes_path
    else
      flash[:failure] = @prize.value[:error_message]
      @prize = params[:prize]
      render :edit
    end
  end

  def destroy
    render :json => @prizes_client.destroy(params[:id])
  end

# old

  before_filter :check_prize_existence, :only => [:show, :update, :destroy]

  def check_prize_existence
    @prize = Prize.find_by_id(params[:id])
    render_json_auto ErrorEnum::PRIZE_NOT_EXIST and return if @prize.nil?
  end

  def show
    @prize['photo_url'] = @prize.photo.value
    render_json_auto(@prize)
  end

  def index
    render_json { auto_paginate(Prize.search_prize(params[:title], params[:type].to_i)) }
  end

  def show
    @prize['photo_url'] = @prize.photo.value
    render_json_auto(@prize)
  end

  def create
    render_json Prize.create_prize(params[:prize]) and return
  end

  def update
    render_json_auto @prize.update_prize(params[:prize]) and return
  end

  def destroy
    render_json_auto @prize.delete_prize and return
  end
  
end
