class SubscribersController < ApplicationController
  before_filter :set_access_control_headers
    def  set_access_control_headers
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Request-Method'] = '*'
      headers['Access-Control-Allow-Headers'] = '*'
      headers['Access-Control-Allow-Credentials'] = 'true'
    end


  def index

  end

  def create
    retval = if params[:e].to_s.match(/^([a-zA-Z0-9_\.\-])+\@(([a-zA-Z0-9\-])+\.)+([a-zA-Z0-9]{2,4})+$/)
      Subscriber.find_or_create_by(:email => params[:e])
      success_true
    end
    render :json => {:success => retval}, :callback => params[:callback]
  end

  def destroy
    retval = if params[:e].to_s.match(/^([a-zA-Z0-9_\.\-])+\@(([a-zA-Z0-9\-])+\.)+([a-zA-Z0-9]{2,4})+$/)
      if subscriber = Subscriber.where(:email => params[:e]).first
        success_true if subscriber.unsubscribe
      end
    end
    render :json => {:success => retval}, :callback => params[:callback]
  end
end
