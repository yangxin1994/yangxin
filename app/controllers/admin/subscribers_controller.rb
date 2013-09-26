# encoding: utf-8
# already tidied up

class Admin::SubscribersController < Admin::AdminController
  layout "layouts/admin-todc"

  def index
    @subscribers = auto_paginate Subscriber.search(params)
  end

  def new

  end
  

  def create
    render_json true do
      subscribers = params[:subscribers].gsub('，',',')
      subscribers = subscribers.gsub("\n",',')
      subscribers = subscribers.gsub(' ','')
      subscribers = subscribers.split(',')
      s_count = f_count = e_count = 0
      batch = []
      subscribers.each do |email|
        if email.to_s.match(/^([a-zA-Z0-9_\.\-])+\@(([a-zA-Z0-9\-])+\.)+([a-zA-Z0-9]{2,4})+$/)
          if Subscriber.where(:email => email.downcase).exists?
            e_count += 1
          else
            batch << {:email => email.downcase}
            s_count += 1
          end
        else
          f_count += 1
        end
      end
      Subscriber.collection.insert(batch) unless batch.empty?
      {:s_count => s_count, :e_count => e_count,:f_count => f_count}
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

end