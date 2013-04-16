class Admin::NewslettersController < Admin::ApplicationController

  def index
    render_json true do
      auto_paginate(Newsletter.all)
    end
  end

  def_each :deleted, :editing, :delivering, :delivered, :canceled do |method_name|
    render_json auto_paginate(Newsletter.send(method_name))
  end

  def create
    render_json true do
      Newsletter.create(params[:newsletter])
    end
  end

  def show
    render_json false do
      Newsletter.find_by_id(params[:id]) do |nl|
        success_true
        nl
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
        success_true
        nl.assign_attributes(params[:newsletter])
        nl.save
      end
    end
  end

  def deliver
    render_json false do
      Newsletter.find_by_id(params[:id]) do |nl|
        success_true
        nl.deliver_news
      end
    end
  end

  def test
    render_json false do
      Newsletter.find_by_id(params[:id]) do |nl|
        success_true
        nl.deliver_test_news(current_user)
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