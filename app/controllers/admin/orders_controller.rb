class Admin::OrdersController < Admin::ApplicationController
  
  def index
    render_json true do
      auto_paginate(Order.all) do |orders|
        orders.page(page).per(per_page).map do |o|
          o["gift_name"] = o.gift.name
          o
        end
      end
    end
  end
  
  def delete
    @orders = []
    params[:ids].to_a.each do |id|
      @orders << (Order.find_by_id id do |r|
        r.delete
      end)
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

  def update
    @order = @current_user.orders.find_by_id(params[:id])
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

  def_each :need_verify, :verified, :verify_failed, :delivering, :delivering, :delivered, :deliver_failed do |method_name|
    render_json true do
      #Order.send(method_name).page(page)
      auto_paginate(Order.send(method_name)) do |orders|
        orders.page(page).per(per_page).map do |o|
          o["gift_name"] = o.gift.name
          o
        end
      end
    end
  end
  
end