# encoding: utf-8
# already tidied up

require "csv"
require 'string/utf8'
class Admin::OrdersController < Admin::AdminController

  layout "layouts/admin-todc"

  before_filter :require_sign_in, :only => [:index, :update, :destroy]

  def index
    params.each{|k, v| params.delete(k) unless v.present?}
    if params[:keyword]
      if params[:keyword] =~ /^.+@.+$/
        params[:email] = params[:keyword]
      elsif params[:keyword].length == 13
        params[:code] = params[:keyword]
      else
        params[:mobile] = params[:keyword]
      end
      params.delete :keyword
    end
    order_list = Order.search_orders(params[:email], 
      params[:mobile],
      params[:code],
      params[:status].to_i,
      params[:source].to_i,
      params[:type].to_i).desc(:created_at)
    @orders = auto_paginate(order_list) do |orders|
      orders.map { |e| e.info_for_admin }
    end
    respond_to do |format|
      format.json { render_json_auto @orders }
      format.html { }
    end
  end

  def handle
    render_json Order.where(:_id => params[:id]).first do |order|
      order.manu_handle
    end
  end

  def bulk_handle
    result = @orders_client.bulk_handle(params[:ids])
    render :json => result

  end

  def finish
    render_json Order.where(:_id => params[:id]).first do |order|
      order.finish(params[:success] == 'true', params[:remark])
    end
  end

  def bulk_finish
    result = @orders_client.bulk_finish(params[:ids])

    render :json => result
  end

  def update_express_info
    render_json Order.where(:_id => params[:id]).first do |order|
      order.update_express_info(params[:express_info])
    end
  end

  def update_remark
    render_json Order.where(:_id => params[:id]).first do |order|
      order.update_remark(params[:remark]) 
    end
  end

  def to_excel
    result = @orders_client.to_excel(params[:scope])
    if result.success
      send_data(result.value, :filename => "订单数据#{Time.now.strftime("%Y-%M-%d")}.csv", :type => 'text/csv')
    else

    end
  end

end