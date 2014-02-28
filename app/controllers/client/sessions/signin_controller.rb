# encoding: utf-8
# already tidied up

class Client::Sessions::SigninController < Client::ApplicationController

  skip_before_filter :require_client

  # PAGE: show sign in
  def index

  end

  def show
    
  end

  # AJAX: sign in
  def create
    # render_json Client.where(:email => params[:client][:email], 
    #   :password => Encryption.encrypt_password(params[:client][:password])).first do |client|
    #   client && client.login
    # end
    begin
      auth_key = Client.login(params[:client][:email], params[:client][:password])
    rescue Exception => e
      flash.alert = "用户名和密码不匹配!"
      render :index
    else
      session[:auth_key] = auth_key
      redirect_to client_surveys_url, :flash => { :success => "登录成功!" }
    end
  end
end
