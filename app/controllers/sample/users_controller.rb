# coding: utf-8
class Sample::UsersController < Sample::SampleController

  before_filter :require_sign_in, :get_client
  before_filter :get_self_extend_info, :except => [:survey_detail, :spread_counter, 
                                      :update_logistic_address, :update_password, 
                                      :destroy_notification, :remove_notifications,
                                      :unbind, :bind_share, :bind_subscribe, :update_basic_info,
                                      :change_mobile, :check_mobile_verify_code, :change_email]
  before_filter :setting_nav,:only => [:basic_info, :avatar, :update_avatar ,:bandings,:address, :password, :bindings, :reset_pass]
  before_filter :survey_nav,:only => [:join_surveys,:index, :spread_surveys, :survey_detail]
  before_filter :point_nav,:only => [:points]
  before_filter :order_nav,:only => [:orders, :from_lottery, :from_point, :order_show]
  before_filter :job_nav, :only => [:jobs]
  before_filter :notification_nav, :only => [:notifications]


  def initialize
    super('users')
  end

  def get_mobile_area 
    @retval = QuillCommon::MobileUtility.region_and_carrier(params[:m])
    render :json => false and return if @retval["retmsg"].to_s != "OK"
    @retval = "#{@retval['city']}, 中国 #{@retval['carrier']}"
    render :json => @retval and return
  end

  # *********************************
  # ============Different Partial of User Center Page==============================

  # ************ surveys *********************

  # 我参加的调研
  # GET
  def join_surveys
    @my_answer_surveys = @uclient.get_my_surveys(page, per_page)

    data = @my_answer_surveys.value["data"].map do |item |
      # Need attrs: rewards, answer_status, answer_id, amount
      # maybe it has too many attrs, so i did not use helper method.

      # select reward
      item["select_reward"] = ""
      # 
      item["free_reward"] = item["rewards"].to_a.empty?
      item["rewards"].to_a.each do |rew|
        # if rejected, reward in empty
        item["select_reward"] = "" and break if item["answer_status"].to_i == 2 

        if rew["checked"]
          case rew["type"].to_i
          when 1
            item["select_reward"] = "#{rew["amount"].to_i}元话费"
          when 2
            item["select_reward"] = "#{rew["amount"].to_i}元支付宝"
          when 4 
            item["select_reward"] = "#{rew["amount"].to_i}积分"
          when 8
            lottery_link = "/lotteries/#{item["answer_id"]}"
            item["select_reward"] = %Q{<a class='lottery' target='_blank' href='#{lottery_link}'>抽奖机会</a>}
          when 16
            item["select_reward"] = "#{rew["amount"].to_i}集分宝"
          end

          break
        end
      end

      # return
      item 
    end

    @my_answer_surveys.value["data"] = data

    respond_to do |format|
      format.html { render 'join_surveys' } # adapt to alias index action
      format.json { render :json => @my_answer_surveys }
    end
  end

  alias :index :join_surveys

  #我推广的问卷
  # GET
  def spread_surveys
    @my_spread_surveys = @uclient.my_spread_surveys(page, per_page)

    respond_to do |format|
      format.html 
      format.json { render :json => @my_spread_surveys }
    end
  end

  # GET
  def survey_detail
    @answers = @uclient.survey_spread_answers(params[:id], page, 9)

    respond_to do |format|
      format.html {
        render :layout => false if request.headers["OJAX"]
      }
      format.json { render :json => @answers }
    end
  end

  # GET
  def spread_counter
    @counter = @uclient.spread_answers_number(params[:id])

    respond_to do |format|
      format.json { render :json => @counter }
    end
  end

  # *************** points ****************
  
  #积分记录
  # GET
  # params[:scope] = :all | :in | :out
  def points
    @point_logs = @uclient.get_my_point_history(params[:scope], page, per_page)

    respond_to do |format|
      format.html 
      format.json { render :json => @point_logs }
    end
  end

  # **************** orders ***************

  # 我的礼品
  # ** scope: answer/lottery/point
  # 
  def orders
    scope = [1,2,4].include?(params[:scope].to_i) ? params[:scope].to_i : 1
    @orders = @uclient.get_my_orders(scope, page, per_page)

    respond_to do |format|
      format.html 
      format.json { render :json => @orders }
    end
  end
  #

  #订单详情查询
  def order_detail
    @order = @uclient.order_show(params[:id])

    respond_to do |format|
      format.html {
        # render_options = {:layout => false}
        # render_options.merge!({:text => "请求出现错误！"}) unless @order.success
        # render render_options if request.headers["OJAX"]
        render :layout => false if request.headers["OJAX"]
      }
      format.json { render :json => @order }
    end
  end

  # ************** setting *****************

  # def setting
  # end

  #个人资料
  # GET
  def basic_info
    @user_info = @uclient.basic_attrs

    respond_to do |format|
      format.html {
        render :text => "error!" and return unless @user_info.success
        @user_info = @user_info.value

        # Just for test
        # 
        # @user_info["nickname"]="aaaaaa"
        # @user_info["username"]="bbb"
        # @user_info["gender"]= 1
        # @user_info["birthday"]= [946656000,946656000]
        # @user_info["born_address"]="4161"
        # @user_info["live_address"]="4162"
        # @user_info["married"]=1
        # @user_info["children"]=1
        # @user_info["income_person"]=[0,2000]
        # @user_info["income_family"]=[3000,5000]
        # @user_info["education_level"]=2
        # @user_info["major"]=6
        # @user_info["industry"]=6
        # @user_info["position"]=13
        # @user_info["seniority"]=[0,1]

        # change -1 to 99999999
        @user_info["income_person"][1] = 99999999 if @user_info["income_person"].is_a?(Array) and @user_info["income_person"][1] == -1
        @user_info["income_family"][1] = 99999999 if @user_info["income_family"].is_a?(Array) and @user_info["income_family"][1] == -1
        @user_info["seniority"][1] = 99999999 if @user_info["seniority"].is_a?(Array) and @user_info["seniority"][1] == -1
      }
      format.json { render :json => @user_info }
    end
  end

   #更改基本信息
   # PUT
  def update_basic_info
    # logger.error ".........\n#{params[:attrs].inspect}"
    param_attrs = params[:attrs].select{|e| %w(nickname username gender birthday born_address 
                        live_address married children income_person income_family
                        education_level major industry position seniority).include?(e)}
    
    # remove blank attrs
    %w(nickname username).each do |item|
      param_attrs.delete item if param_attrs[item].to_s.blank?
    end

    %w(gender birthday born_address 
      live_address married children income_person income_family
      education_level major industry position seniority).each do |item|
      param_attrs.delete item if param_attrs[item].nil? || param_attrs[item].to_i == -1
    end

    # format attrs
    param_attrs["income_person"] = param_attrs["income_person"].split('_').collect!{|e| e.to_i } if param_attrs["income_person"]
    # change 99999999 to -1
    param_attrs["income_person"][1] = -1 if param_attrs["income_person"].is_a?(Array) and param_attrs["income_person"][1] == 99999999

    param_attrs["income_family"] = param_attrs["income_family"].split('_').collect!{|e| e.to_i} if param_attrs["income_family"]
    # change 99999999 to -1
    param_attrs["income_family"][1] = -1 if param_attrs["income_family"].is_a?(Array) and param_attrs["income_family"][1] == 99999999

    param_attrs["seniority"] = param_attrs["seniority"].split('_').collect!{|e| e.to_i} if param_attrs["seniority"]
    # change 99999999 to -1
    param_attrs["seniority"][1] = -1 if param_attrs["seniority"].is_a?(Array) and param_attrs["seniority"][1] == 99999999
    
    param_attrs["birthday"] = [param_attrs["birthday"].to_i, param_attrs["birthday"].to_i] if param_attrs["birthday"]    

    %w(gender born_address live_address married children education_level major industry position).each do |item|
      param_attrs[item] = param_attrs[item].to_i if param_attrs[item]
    end

    @retval = @uclient.update_attrs(param_attrs)

    respond_to do |format|
      format.html {
        redirect_to :action => :basic_info
      }
      format.json { render :json => @retval }
    end
  end

  # GET 头像信息
  # return avatar link and email
  def avatar

  end

  #更新头像信息
  # POST
  def update_avatar
    if @current_user 
      avatar = Avatar.new 
      avatar.uid = @current_user['sample_id']
      unless params[:crop].empty?
        geo_arr = params[:crop].split(',').reverse
        avatar.crop_w = geo_arr[0]
        avatar.crop_h = geo_arr[1]
        avatar.crop_x = geo_arr[2]
        avatar.crop_y = geo_arr[3]
      end
      avatar.image = params[:avatar]
      avatar.store_image!
    end
    redirect_to action: 'avatar'
  end

  #账户绑定
  # GET /users/setting/bindings
  def bindings
    @bindings = @uclient.bindings

    respond_to do |format|
      format.html {
        render :text => "error!" and return unless @bindings.success
        @bindings = @bindings.value
      }
      format.json { render :json => @bindings }
    end
  end

  #取消绑定具体账户
  # PUT /users/setting/unbind/:website
  def unbind
    @retval = @uclient.unbind(params[:website])

    respond_to do |format|
      format.html {
        render :text => "error!", action: 'bindings' and return unless @retval.success
      }
      format.json { render :json => @retval }
    end
  end

  # 绑定分享
  # PUT /users/setting/share?website=&share=
  def bind_share
    @retval = @uclient.set_share(params[:website], params[:share])

    respond_to do |format|
      format.html {
        render :text => "error!", action: 'bindings' and return unless @retval.success
      }
      format.json { render :json => @retval }
    end
  end

  # 绑定订阅
  # PUT /users/setting/subscribe?type=&sub=
  def bind_subscribe
    @retval = @uclient.set_subscribe(params[:type], params[:sub])

    respond_to do |format|
      format.html {
        render :text => "error!", action: 'bindings' and return unless @retval.success
      }
      format.json { render :json => @retval }
    end
  end

  # 根据手机号发送验证短信
  # PUT /users/setting/change_mobile?m=
  def change_mobile
    @retval = @uclient.change_mobile(params[:m])

    render :json => @retval 
  end

  # 根据手机号和验证短信码激活手机
  # PUT /users/setting/check_mobile_verify_code?m=&code=
  def check_mobile_verify_code
    @retval = @uclient.check_mobile_verify_code(params[:m], params[:code])

    render :json => @retval 
  end

  # 根据邮箱绑定
  # PUT /users/setting/change_mobile?email=
  def change_email
    @retval = @uclient.change_email(params[:email], "")

    render :json => @retval 
  end

  #收获地址
  # GET
  def address
    @receiver_info = @uclient.get_logistic_address

    respond_to do |format|
      format.html {
        render :text => "error!" and return unless @receiver_info.success
        @receiver_info = @receiver_info.value
      }
      format.json { render :json => @receiver_info }
    end
  end

  # PUT
  def update_logistic_address
    @retval = @uclient.update_logistic_address(params[:receiver_info])

    respond_to do |format|
      format.html {
        render :text => "error!", action: 'address' and return unless @retval.success
      }
      format.json { render :json => @retval }
    end
  end

  # 密码
  # GET
  def password 

  end

  # PUT
  def update_password
    @retval = @uclient.reset_password(params[:old_password], params[:new_password])

    respond_to do |format|
      format.html {
        render :text => "error!", action: 'password' and return unless @retval.success
      }
      format.json { render :json => @retval }
    end
  end

  # ************* notifications ******************    

  def notifications
    @notices = @uclient.notifications(page, per_page)

    respond_to do |format|
      format.html 
      format.json { render :json => @notices }
    end
  end

  # DELETE
  # Delete notice from id
  def destroy_notification
    @retval = @uclient.del_notice(params[:id])

    respond_to do |format|
      format.html {
        redirect_to action: 'notifications' and return unless @retval.success
      }
      format.json { render :json => @retval }
    end
  end

  # DELETE
  # Delete All notifications
  def remove_notifications
    @retval = @uclient.del_all_notices

    respond_to do |format|
      format.html {
        redirect_to action: 'notifications' and return unless @retval.success
      }
      format.json { render :json => @retval }
    end
  end

  # *******************************
  # =============================================
  # *******************************************

  private 
  
  def get_client
    @uclient = Sample::UserClient.new(session_info) 
  end

  def get_self_extend_info
    @current_user  = @uclient.get_basic_info.value   
  end

  def setting_nav
    @current_nav = 'setting'  
  end

  def survey_nav
    @current_nav = 'surveys'  
  end

  def point_nav
    @current_nav = 'points' 
  end

  def order_nav
    @current_nav = 'orders' 
  end

  def job_nav
    @current_nav = 'jobs'
  end

  def notification_nav
    @current_nav = 'notifications'
  end

end