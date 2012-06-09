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
    
    #tp_user = SinaUser.where(:user_id => "1957822497")[0]
    #@info = "no info."
    #@info = tp_user.call_method() if tp_user
    #@info = tp_user.say_text("第三方登录测试发送微博5。")
    #@info = tp_user.say_text("第三方登录测试发送微博。加个链接试试：http://liucm.sinaapp.com")
    #@info = tp_user.repost_text("3454675519532348")
    #@info = tp_user.repost_text_with_message("3454675519532348","with message")
    
    tp_user = QqUser.where(:user_id => "2504A9A310DDCC3DD9823B59323D3A47")[0]
    @info = "no info."
    #@info = tp_user.call_method()
    #@info = tp_user.add_share("测试分享功能","http://liucm.sinaapp.com/index.php/archives/5/", "个人博客", "正如标题, 今天是星期六，而我在公司这里。")
    
  rescue => ex 
    flash[:notice] = "error: #{ex.class} => #{ex.message}"
    raise ex
  ensure 
    render :controller => :home, :action => :index
  end
  
  private
  
end
