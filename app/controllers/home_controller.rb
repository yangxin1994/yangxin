# coding: utf-8

class HomeController < ApplicationController

  before_filter :require_sign_in
	# method: get
	# description: the home page of an user
  def index
		if user_signed_out?
			redirect_to root_path and return
		end
  end

  #Post
  #
  # 
  def get_tp_info
    @tp_user = ThirdPartyUser.find_by_email(@current_user.email)
    
    if !@tp_user then
      flash[:notice] = "你未绑定第三方帐户，未有获取信息的功能！"
    else 
		  
		  retval = Tool.send_post_request("https://api.renren.com/v2/user?access_token=#{@tp_user.access_token}", true)
  		response_data = JSON.parse(retval.body)  		
  		@user = response_data[:user]
      
    end
    
  rescue => ex
    flash[:error] = "error type: #{ex.class}, message: #{ex.message}"
    
    reget_access_token
  ensure
    render :controller => :home, :action => :index
  end
  
  #####
  # POST 
  def get_more_info
    @tp_user = ThirdPartyUser.find_by_email(@current_user.email)
    
    renren =Renren::Base.new(@tp_user.access_token)
    
    #@info = renren.call_method({:method => "share.share", :type => 6, :url => "http://wiki.dev.renren.com/wiki/Share.share", :comment => "好不好 其实我也不知道" })
    # get error
    
    @info = renren.call_method({:method => "status.gets"})
    #get error
    
    #@info = renren.call_method
  rescue => ex
    flash[:error] = "error type2: #{ex.class}, message: #{ex.message}"
    
  ensure
    render :controller => :home, :action => :index
  end
  
  private
  
  def reget_access_token
    #@tp_user = ThirdPartyUser.find_by_email(@current_user.email)
    
    access_token_params = {"client_id" => OOPSDATA[RailsEnv.get_rails_env]["renren_api_key"],
			"client_secret" => OOPSDATA[RailsEnv.get_rails_env]["renren_secret_key"],
			"redirect_uri" => OOPSDATA[RailsEnv.get_rails_env]["renren_redirect_uri"],
			"grant_type" => "refresh_token",
			"refresh_token" => @tp_user.refresh_token}
    retval = Tool.send_post_request("https://graph.renren.com/oauth/token", access_token_params, true)
		@response_data = JSON.parse(retval.body)
		
		@access_token = @response_data["access_token"]
		@refresh_token = @response_data["refresh_token"]
		
		@user = @response_data["user"]
	
	  #@tp_user.update_access_token(access_token)
	  #@tp_user.update_refresh_token(refresh_token)
  rescue => ex
    flash[:error] = "error type: #{ex.class}, message: #{ex.message}"
  end  
end
