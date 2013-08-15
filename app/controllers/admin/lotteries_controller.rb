#encoding: utf-8

class Admin::LotteriesController < Admin::AdminController

  layout "layouts/admin_new"

  before_filter :require_sign_in, :only => [:index, :create, :update, :destroy]

  before_filter :get_lottery_client

  def get_lottery_client
    @lottery_client = Admin::LotteryClient.new(session_info)
  end

  def index
    @lottery_scopes = {
      "all" => "所有抽奖",
      "quillme" => "QM显示的抽奖",
      "for_publish" => "待发布的抽奖活动",
      "activity" => "进行中的抽奖",
      "finished" => "已结束的抽将"
    }
    @lottery_scope = params[:scope] || 'all'
    #@lottery_client.uri_prefix = "/lotteries"
    result = @lottery_client.index(page, per_page, @lottery_scope)
    pc = Admin::PrizeClient.new(session_info).for_lottery
    if result.success && pc.success
      respond_to do |format|
        format.html do
          @lotteries = result.value
          @prizes = pc.value
          if params[:partial]
            render :partial => 'lotteries'
          end
        end
        format.json do
          render :json => result
        end
      end

    else
      render :json => result.success ? pc : result
    end
  end

  def show
    respond_to do |format|
      format.html do
        # @lottery = @lottery_client.show(params[:id])
        @lottery = @lottery_client.ctrl(params[:id], true)
        # @users = BaseClient.new(session_info, "/admin/users")._get(
        #   :page => params[:page],
        #   :per_page => params[:per_page] || 10)
        if @lottery.success #&& @users.success
          #@users = @users.value
          @lottery = @lottery.value
          @prizes = @lottery["prizes"]
        else
          render :json => @lottery
        end
      end
      format.json do
        render :json => @lottery_client.show(params[:id])
      end
    end
  end

  def new
    @lottery = {}
  end

  def edit

    @lottery = @lottery_client.show(params[:id])
    # binding.pry
    if @lottery.success
      @lottery = @lottery.value
      @prizes = @lottery["prizes"]
    else
      render :json => @lottery
    end
  end

  def reward_records
    @lottery = @lottery_client.show(params[:id])
    @lottery_codes = @lottery_client.prize_records(params[:id], page)
    if @lottery_codes.success
      @lottery_codes = @lottery_codes.value
      @lottery = @lottery.value
      if params[:partial]
        render :partial => "lottery_codes"
      end
    end
  end

  def lottery_codes
    @lottery = @lottery_client.show(params[:id])
    @lottery_codes = @lottery_client.lottery_codes(params[:id], page)
    if @lottery_codes.success
      @lottery_codes = @lottery_codes.value
      @lottery = @lottery.value
      if params[:partial]
        render :partial => "lottery_codes"
      end
    end
  end

  def create
    #render :json => @lottery_client.send_data
    photo = ImageUploader.new
    photo.store!(params[:lottery][:photo])
    params[:lottery][:photo] = photo.url
    params[:lottery][:exchangeable] = !!params[:lottery][:exchangeable]
    @lottery = @lottery_client.create(params[:lottery])
    # render :json => @lottery
    if @lottery.success
      flash.keep[:success] = "活动被成功创建了~"
      redirect_to admin_lotteries_path + "/#{@lottery.value["_id"]}"
    else
      flash.now[:failure] = "是不是哪里填错了?再检查一遍吧"
      @lottery = {}
      render :new
    end
  end

  def update
    unless params[:lottery][:photo].nil?
      photo = ImageUploader.new
      photo.store!(params[:lottery][:photo])
      params[:lottery][:photo] = photo.url
    end
    params[:lottery][:exchangeable] = !!params[:lottery][:exchangeable]
    @lottery = @lottery_client.update(params[:id], params[:lottery])
    if @lottery.success
      flash.keep[:success] = "活动被成功修改了~"
      redirect_to admin_lotteries_path + "/#{@lottery.value["_id"]}"
    else
      flash.keep[:success] = "是不是哪里填错了?再检查一遍吧"
      redirect_to admin_lotteries_path + "/#{params[:id]}/edit"
    end
  end

  def deleted
    @lotteries = @lottery_client.index(page, per_page, 'deleted')
    if @lotteries.success
      @lotteries = @lotteries.value
      if params[:partial]
        render :partial => 'deleted_lotteries'
      end
    end
  end

  def status
    params[:lottery] = {}
    params[:lottery][:status] = params[:status]
    render json: @lottery_client.update(params[:id], params[:lottery])
  end

  def list_user
    @users = BaseClient.new(session_info, "/admin/users")._get(
      :page => params[:page],
      :per_page => params[:per_page] || 10)
    @lottery = @lottery_client.show(params[:id])
    if @users.success && @lottery.success
      @users = @users.value
      @prizes = @lottery.value['prizes']
    end
    render :partial => "list_user"
  end

  def ctrl
    @lottery = @lottery_client.ctrl(params[:id], params[:only_active])
    if @lottery.success
      @lottery = @lottery.value
    else
      render :json => @lottery
    end
  end

  def add_ctrl_rule
    render :json => @lottery_client.add_ctrl_rule(params[:ctrl_prize],
     params[:ctrl_surplus],
     params[:ctrl_time],
     params[:weight])
  end

  def assign_prize
    @users = BaseClient.new(session_info, "/admin/users")._get(
      :page => params[:page],
      :per_page => params[:per_page] || 10,
      :email => params[:email],
      :full_name => params[:full_name],
      :username => params[:username])
    @lottery = @lottery_client.show(params[:id])
    if @users.success && @lottery.success
      @users = @users.value
      @prizes = @lottery.value['prizes']
      @lottery = @lottery.value
      if params["partial"]
        render 'user_list'
      end
    else
      render :json => @lottery
    end
  end

  def revive
    render :json => @lottery_client.revive(params[:id])
  end

  def assign_prize_to
    render :json => @lottery_client.assign_prize(params[:id], params[:user_id], params[:prize_id])
  end

  def destroy
    render :json => @lottery_client.destroy(params[:id])
  end

  def auto_draw
    render :json => @lottery_client.auto_draw(params[:id])
  end

end