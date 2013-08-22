# encoding: utf-8

require "csv"
require 'string/utf8'
class Admin::OrdersController < Admin::AdminController

  layout "layouts/admin-todc"

  before_filter :require_sign_in, :only => [:index, :update, :destroy]

  before_filter :get_orders_client

  def get_orders_client
    @orders_type = { "0" => ["cash", "现金"],
                     "1" => ["entity", "实物"],
                     "2" => ["virtual", "虚拟"],
                     "3" => ["lottery", "抽奖"]}
    @orders_client = Admin::OrderClient.new(session_info)
  end

  def index
    result = @orders_client.index(params)
    if result.success
      @orders = result.value
    else
      render :json => result
    end
  end

  def handle
    result = @orders_client.handle(params[:id])
    render :json => result
  end

  def bulk_handle
    result = @orders_client.bulk_handle(params[:ids])
    render :json => result

  end

  def finish
    result = @orders_client.finish(params)

    render :json => result
  end

  def bulk_finish
    result = @orders_client.bulk_finish(params[:ids])

    render :json => result
  end

  def update_express_info
    render :json => @orders_client.update_express_info(params)
  end

  def update_remark
    render :json => @orders_client.update_remark(params)
  end

  def to_excel
    result = @orders_client.to_excel(params[:scope])
    if result.success
      send_data(result.value, :filename => "订单数据#{Time.now.strftime("%Y-%M-%d")}.csv", :type => 'text/csv')
    else

    end
  end

#   
  def index
    order_list = Order.search_orders(params[:email], 
      params[:mobile],
      params[:code],
      params[:status].to_i,
      params[:source].to_i,
      params[:type].to_i).desc(:created_at)
    @paginated_order_list = auto_paginate(order_list) do |paginated_order_list|
      paginated_order_list.map { |e| e.info_for_admin }
    end
    render_json_auto @paginated_order_list and return
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
    render_json_auto @order.update_express_info(params[:express_info]) and return
  end

  def update_remark
    render_json_auto @order.update_remark(params[:remark]) and return
  end

end