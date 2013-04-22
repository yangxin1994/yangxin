class Admin::NewslettersController < Admin::ApplicationController

  def index
    render_json true do
      auto_paginate(Newsletter.all.present_json('list'))
    end
  end

  def_each :deleted, :editing, :delivering, :delivered, :canceled do |method_name|
    render_json auto_paginate(Newsletter.send(method_name).present_json('list'))
  end

  def create
    render_json true do
      nl = Newsletter.create(params[:newsletter])
      nl.present_admin
    end
  end

  def show
    render_json false do
      Newsletter.find_by_id(params[:id]) do |nl|
        success_true
        nl.present_admin
      end
    end
  end

  def destroy
    render_json false do
      Newsletter.find_by_id(params[:id]) do |nl|
        success_true
        nl.is_deleted = true
        nl.save
      end
    end
  end

  def update
    render_json false do
      Newsletter.find_by_id(params[:id]) do |nl|
        nl.assign_attributes(params[:newsletter])
        success_true if nl.save
      end
    end
  end

  def deliver
    render_json false do
      Newsletter.find_by_id(params[:id]) do |nl|
        success_true
        nl.deliver_news(params[:content])
      end
    end
  end

  def test
    render_json false do
      Newsletter.find_by_id(params[:id]) do |nl|
        params[:email].split(',').each do |em|
          if em.to_s.match(/^([a-zA-Z0-9_\.\-])+\@(([a-zA-Z0-9\-])+\.)+([a-zA-Z0-9]{2,4})+$/)
            subscriber = Subscriber.find_or_create_by(:email => em.downcase)
            nl.deliver_test_news(subscriber ,params[:content])
            success_true
          end
        end
      end
    end
  end

  def cancel
    render_json false do
      Newsletter.find_by_id(params[:id]) do |nl|
        success_true
        nl.cancel
      end
    end
  end
end