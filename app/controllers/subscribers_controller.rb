class SubscribersController < ApplicationController

  def index

  end

  def create
    render_json do
      Subscriber.find_or_create_by(:email => params[:email])
    end
  end

  def destroy
    render_json false do
      if subscriber = Subscriber.where(:email => params[:email]).first
        success_true if subscriber.unsubscribe
      end
    end
  end
end
