# encoding: utf-8

class Admin::SubscribersController < Admin::AdminController
  layout "layouts/admin_new"

  before_filter :require_sign_in
  before_filter :get_subscribers_client
  def get_subscribers_client
    @subscribers_client = Admin::SubscriberClient.new(session_info)
  end

  def index
    result = @subscribers_client.index(page , per_page, params[:scope] || 'all', params[:s])
    if result.success
      @subscribers = result.value
      p @subscribers
      if params[:partial]
        render :partial => "subscribers"
      end
    else
      render :text => "数据加载失败请稍后重试!"
    end
  end
  def new

  end
  def subscribe
    render :json => @subscribers_client.subscribe(params[:id])
  end
  def destroy
    render :json => @subscribers_client.destroy(params[:id])
  end
  def create
    render :json => @subscribers_client.create(params[:subscribers])
  end
  def unsubscribe
    render :json => @subscribers_client.unsubscribe(params[:id])
  end
end