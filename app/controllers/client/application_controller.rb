# encoding: utf-8
class Client::ApplicationController < ApplicationController
  layout 'layouts/client'
  
  before_filter :require_client
  helper_method :client_signed_in, :current_client

  def require_client
    if session[:auth_key].blank? || session[:auth_key] != current_client.try('auth_key')
      redirect_to "/client/signin", :notice => "您需要登录才能继续操作!" and return
    end
  end

  def client_signed_in
    return !!current_client
  end

  def current_client
    @current_client = Client.find_by_auth_key(session[:auth_key])
  end
end
