#encoding: utf-8

class Admin::GiftsController < Admin::AdminController

  layout "layouts/admin-todc"

  before_filter :require_sign_in, :only => [:index, :create, :update, :destroy]

  before_filter :get_gift_client
  before_filter :convert_params

  def get_gift_client
    @gift_client = Admin::GiftClient.new(session_info)
  end

  def index
    result = @gift_client.index(
      :page     => page,
      :per_page => per_page,
      :title    => params[:title],
      :status   => params[:status],
      :type     => params[:type])
    if result.success
      @gifts = result.value
      if params[:partial]
        render :partial => "gifts"
      end
    else
      render :json => result
    end
  end

  def show
    #render :json => @gift_client.show(params[:id])
    @gift = @gift_client.show(params[:id])
    respond_to do |format|
      format.html do
        render :layout => false
      end
      format.json do
        render :json => @gift
      end
    end
  end

  def new
    @gift = {}
  end

  def create
    photo = ImageUploader.new
    photo.store!(params[:gift][:photo])

    params[:gift].delete(:photo)
    params[:gift][:photo_url] = photo.url

    @gift = @gift_client.create(params[:gift])
    if @gift.success
      flash.keep[:success] = "礼品被成功创建了~"
      redirect_to admin_gifts_path
    else
      flash.now[:failure] = "是不是填错了什么信息?再检查一遍吧"
      @gift = @gift.value
      render :new
    end
  end

  def edit
    @gift = @gift_client.show(params[:id])
    if @gift.success
      @gift = @gift.value
    else
      render :json => @gift
    end
  end

  def update
    if params[:gift][:photo]
      photo = ImageUploader.new
      photo.store!(params[:gift][:photo])
      params[:gift].delete(:photo)
      params[:gift][:photo_url] = photo.url
    end

    @gift = @gift_client.update(params[:id], params[:gift])
    if @gift.success
      redirect_to admin_gifts_path
    else
      flash[:failure] = @gift.value[:error_message]
      @gift = params[:gift]
      render :edit
    end
  end

  def destroy
    render :json => @gift_client.destroy(params[:id])
  end

  def outstock
    params[:gift] = {}
    params[:gift][:status] = 2
    render :json => @gift_client.update(params[:id], params[:gift])
  end

  def stockup
    params[:gift] = {}
    params[:gift][:status] = 1
    render :json => @gift_client.update(params[:id], params[:gift])
  end

  def_each :virtual, :cash, :entity do |method_name|
    if params[:stockout]
      @gifts = Gift.send(method_name).stockout.page(page).per_page(per_page)
    elsif params[:expired]
      @gifts = Gift.send(method_name).expired.page(page).per_page(per_page)
    else
      @gifts = Gift.send(method_name).can_be_rewarded.page(page).per_page(per_page)
    end
  end

  private
  def convert_params
    if params[:redeem_number] and params[:number_ary]
      params[:redeem_number][:number_ary] = params[:redeem_number][:number_ary].split()
    end
  end

end
