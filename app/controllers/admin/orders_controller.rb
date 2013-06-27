class Admin::OrdersController < Admin::ApplicationController

  def index
    order_list = Order.search_orders(params)
    render_json_auto auto_paginate(order_list)
  end


  def update
    render_json_auto ErrorEnum::ORDER_TYPE_ERROR and return if ![1, 2, 4, 8].include?(params[:status])

    @order = Order.find_by_id(params[:id])
    render_json_auto ErrorEnum::ORDER_NOT_FOUND and return if @order.blank?

    retval = @order.update_order_status(params[:status], params[:remark])
    render_json_auto retval and return
  end

  def update_status
    render_json_auto ErrorEnum::ORDER_TYPE_ERROR and return if ![1, 2, 4, 8].include?(params[:status])
    retval = {}
    params[:order_ids].each do |order_id|
      order = Order.find_by_id(order_id)
      if order.blank?
        retval[order_id] = ErrorEnum::ORDER_NOT_FOUND
      else
        order.update_order_status(params[:status], params[:remark])
      end
    end
    retval = true if retval.blank?
    render_json_auto retval and return
  end

end