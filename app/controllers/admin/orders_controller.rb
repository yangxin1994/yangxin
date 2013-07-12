class Admin::OrdersController < Admin::ApplicationController

  before_filter :check_order_existence, :only => [:show, :handle, :finish, :update_remark, :update_express_info]

  def check_order_existence
    @order = Order.find_by_id(params[:id])
    render_json_auto ErrorEnum::ORDER_NOT_EXIST and return if @order.nil?
  end

  def index
    order_list = Order.search_orders(params[:email], 
      params[:mobile],
      params[:code],
      params[:status].to_i,
      params[:source].to_i,
      params[:type].to_i)
    render_json_auto auto_paginate(order_list) and return
  end

  def show
    render_json_auto @order and return
  end

  def handle
    render_json_auto @order.manu_handle and return
  end

  def bulk_handle
    params[:order_ids].each do |order_id|
      Order.find_by_id(order_id).try(:manu_handle)
    end
    render_json_auto true and return
  end

  def finish
    render_json_auto @order.finish(params[:success], params[:remark]) and return
  end

  def bulk_finish
    params[:order_ids].each do |order_id|
      Order.find_by_id(order_id).try(:finish, params[:success])
    end
    render_json_auto true and return
  end

  def update_express_info
    render_json_auto @order.update_express_info and return
  end

  def update_remark
    render_json_auto @order.update_remark and return
  end
end