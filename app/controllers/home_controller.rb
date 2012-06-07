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
  
  rescue => ex 
    flash[:error] = "error: #{ex.class} => #{ex.message}"
    raise ex
  ensure 
    render :controller => :home, :action => :index
  end
  
  #####
  # POST 
  def get_more_info
  
    #tp_user = GoogleUser.where(:email => "oopsdata@yeah.net")[0]
    #@info = "no info."
    #@info = tp_user.call_method() if tp_user
    
    #tp_user = RenrenUser.where(:user_id => "464063528")[0]
    #@info = "no info."
    #@info = tp_user.call_method({:method  => "users.hasAppPermission", :ext_perm => "publish_share"}) if tp_user
    #@info = tp_user.call_method({:method  => "status.gets"}) if tp_user
    #@info = tp_user.call_method() if tp_user
    #
    # renren's privileges is not active, why?
    
    tp_user = SinaUser.where(:user_id => "1957822497")[0]
    @info = "no info."
    @info = tp_user.call_method({:method => "users/show", :uid => tp_user.user_id}) if tp_user
    
  rescue => ex 
    flash[:notice] = "error: #{ex.class} => #{ex.message}"
    raise ex
  ensure 
    render :controller => :home, :action => :index
  end
  
  private
  
end
