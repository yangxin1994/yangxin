# encoding: utf-8
# already tidied up

require "csv"
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
    @orders = Order.search_orders(params[:email], 
      params[:mobile],
      params[:code],
      params[:status].to_i,
      params[:source].to_i,
      params[:type].to_i).desc(:created_at)
    @orders = @orders.page(page).per(per_page) if params[:page].present?
    send_data(@orders.to_excel.encode("GBK"),
      :filename => "订单数据#{Time.now.strftime("%M-%d_%T")}.csv", 
      :type => 'text/csv')
  end

end