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
		  
		  #retval = Tool.send_post_request("https://api.renren.com/v2/user?access_token=#{@tp_user.access_token}", true)
  		#response_data = JSON.parse(retval.body)  		
  		#@user = response_data[:user]
  		#the url:"https://api.renren.com/v2/user?access_token= " is unable.
      
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
    
    ## renren Test
    tp  =Renren::Base.new(@tp_user.access_token)
    
    #@info = tp.call_method({:method => "share.share", :type => 6, :url => "http://wiki.dev.renren.com/wiki/Share.share", :comment => "好不好 其实我也不知道" })
    # get error
    
    @info = tp.call_method()
    #get error
    
    ## sina Test
    #@params = {}
    #@params[:access_token] = @tp_user.access_token
    #rece = call_method({:method => "users/show", :uid => @tp_user.user_id.to_i})
    
    ## qq Test
    #@params = {}
    #@params[:access_token] = @tp_user.access_token
    #@params[:oauth_consumer_key] = OOPSDATA[RailsEnv.get_rails_env]["qq_app_id"]
    #@params[:openid] = @tp_user.user_id   
    #rece = qq_call_method
    
    #@info = JSON.parse(rece.body)
  rescue => ex
    flash[:error] = "error type2: #{ex.class}, message: #{ex.message}"
    
  ensure
    render :controller => :home, :action => :index
  end
  
  private
  
  #sina call api method...
  def sina_call_method(opts = {:method => "statuses/user_timeline"})
    paras_url = ""
    @params.merge(opts.select {|k,v| k.to_s!="method"}).each{|k, v| paras_url +="&#{k}=#{v}"}
    paras_url.sub!("&","?")
    Tool.send_get_request("https://api.weibo.com/2/#{opts[:method]}.json#{paras_url}", true) 
  end
  
  #qq call api method
  def qq_call_method(opts = {:method => "get_user_info"})
    paras_url = ""
    @params.merge(opts.select {|k,v| k.to_s!="method"}).each{|k, v| paras_url +="&#{k}=#{v}"}
    paras_url.sub!("&","?")
    Tool.send_get_request("https://graph.qq.com/user/#{opts[:method]}#{paras_url}", true) 
  end
  
   #google call api method
  def google_call_method(opts = {:method => "get_user_info"})
    paras_url = ""
    @params.merge(opts.select {|k,v| k.to_s!="method"}).each{|k, v| paras_url +="&#{k}=#{v}"}
    paras_url.sub!("&","?")
    Tool.send_get_request("https://www.googleapis.com/oauth2/v1/#{opts[:method]}#{paras_url}", true) 
  end
  
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
