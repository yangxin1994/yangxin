class Admin::SubscribersController < Admin::ApplicationController
  before_filter :require_sign_in

  def index
    render_json auto_paginate(Subscriber.all.present_json(:admin))
  end

  def_each :unsubscribed, :subscribed do |method_name|
    render_json auto_paginate(Subscriber.send(method_name).present_json(:admin))
  end

  def create
    render_json true do
      subscribers = params[:subscribers].split(',')
      s_count = f_count = 0
      subscribers.each do |email|
        if subscribe?(email)
          s_count += 1
        else
          f_count += 1
        end
      end
      {:s_count => s_count, :f_count => f_count}
    end
  end

  def unsubscribe
    render_json false do
      if params[:email].to_s.match(/^([a-zA-Z0-9_\.\-])+\@(([a-zA-Z0-9\-])+\.)+([a-zA-Z0-9]{2,4})+$/)
        if subscriber = Subscriber.where(:email => params[:email].downcase).first
          success_true if subscriber.unsubscribe
        else
          false
        end
      end
    end
  end

  def subscribe?(email)
    if email.to_s.match(/^([a-zA-Z0-9_\.\-])+\@(([a-zA-Z0-9\-])+\.)+([a-zA-Z0-9]{2,4})+$/)
      subscriber = Subscriber.find_or_create_by(:email => email.downcase)
      return subscriber.subscribe
    end
    return false
  end
end
