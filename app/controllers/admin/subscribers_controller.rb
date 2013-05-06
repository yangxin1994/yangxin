# encoding: utf-8

class Admin::SubscribersController < Admin::ApplicationController
  before_filter :require_sign_in

  def index
    render_json true do
      if params[:s]
        email = params[:s].downcase
        subscribers = Subscriber.any_of({ :email => /.*#{email}.*/ })
                                .desc(:is_deleted, :created_at)
      else
        subscribers = Subscriber.all
      end
      data = {}
      data[:] = auto_paginate(subscribers) { |data| data.present_json(:admin) }

    end
  end

  def_each :unsubscribed, :subscribed do |method_name|
    render_json true do
      auto_paginate(Subscriber.send(method_name)) do |data|
        data.present_json(:admin)
      end
    end
  end

  def create
    render_json true do
      subscribers = params[:subscribers].gsub('，',',')
      subscribers = subscribers.gsub("\n",',')
      subscribers = subscribers.gsub(' ','')
      subscribers = subscribers.split(',')
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
      Subscriber.find_by_id(params[:id]) do |subscriber|
        success_true if subscriber.unsubscribe
      end
    end
  end

  def subscribe
    render_json false do
      Subscriber.find_by_id(params[:id]) do |subscriber|
        success_true if subscriber.subscribe
      end
    end
  end

  def destroy
    render_json false do
      Subscriber.find_by_id(params[:id]) do |subscriber|
        success_true
        subscriber.destroy
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
