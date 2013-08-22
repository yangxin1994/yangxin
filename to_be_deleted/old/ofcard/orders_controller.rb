class Ofcard::OrdersController < ApplicationController

  def get_wait_orders
    render_json_auto Order.wait_small_charge_orders and return
  end

  def merge_order_id
    render_json_auto Order.merge_order_id(params[:data]) and return
  end

  def get_handled_orders
    render_json_auto Order.handled_orders and return
  end
end