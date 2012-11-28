class Admin::OrdersController < Admin::ApplicationController
  
  def index
    render_json true do
      auto_paginate(Order.all) do |orders|
        orders.page(page).per(per_page).map do |o|
          o["gift_name"] = o.gift.name unless o.gift.nil?
          o
        end
      end
    end
  end
  
  def destroy
    Order.find_by_id(params[:id]) do |r|
      r.delete
    end
    render_json{ @orders }
  end

  def operate
    @orders = []
    params[:ids].to_a.each do |id|
      @orders << (Order.find_by_id id do |r|
        r.operate 1
      end)
    end
    render_json{@orders }
  end

  def verify
    render_json do
      @success = Order.find_by_id params[:id] do |o|
        o.update_attribute(:status, 1)
      end
    end
  end
  
  def verify_as_failed
    render_json do
      @success = Order.find_by_id params[:id] do |o|
        o.update_attribute(:status, -1)
        o.gift.inc(:surplus, 1)
        o.update_attribute(:status_desc, params[:status_desc])
        o.reward_log.revoke_operation(current_user, params[:status_desc])
      end
    end
  end

  def deliver
    render_json do
      @success = Order.find_by_id params[:id] do |o|
        o.update_attribute(:status, 2)
      end
    end
  end

  def deliver_success
    render_json do
      @success = Order.find_by_id params[:id] do |o|
        o.update_attribute(:status, 3)
      end
    end
  end

  def deliver_as_failed
    render_json do
      @success = Order.find_by_id params[:id] do |o|
        o.update_attribute(:status, -3)
        o.gift.inc(:surplus, 1)
        o.update_attribute(:status_desc, params[:status_desc])
        o.reward_log.revoke_operation(current_user, params[:status_desc])
      end
    end
  end

  def update
    @order = Order.find_by_id(params[:id])
    render_json @order.update_attributes(params[:order]) do
      @order.as_retval
    end
  end
  
  def status
    Order.find_by_id params[:id] do |o|
      o.status = params[:status] || o.status
      o.save
    end
  end

  def_each :need_verify, :verified, :canceled, :verify_failed, :delivering, :delivering, :delivered, :deliver_failed do |method_name|
    render_json true do
      #Order.send(method_name).page(page)
      auto_paginate(Order.send(method_name)) do |orders|
        orders.page(page).per(per_page).map do |o|
          o["gift_name"] = o.gift.name unless o.gift.nil?
          o
        end
      end
    end
  end
  
end