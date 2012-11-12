class OrdersController < ApplicationController
#TO DO before_filter
  before_filter :require_user_exist
  def index
    render_json { auto_paginate(@current_user.orders) }
  end

  def show
    # TODO is owners request?
    render_json { @current_user.orders.find_by_id(params[:id])}
  end

  def create
    @order = @current_user.orders.create(params[:order])
    render_json !@order.created_at.nil? do |s|
      @order.as_retval
    end
  end

  # def create
  #   @order = @current_user.orders.create(params[:order])
  #   render_json @order.save do |s|
  #     if s
  #       [:cash_receive_info, :entity_receive_info, :virtual_receive_info, :lottery_receive_info].each do |e| 
  #         @order.send("create_#{e.to_s}",params[:order][e]) if params[:order].include? e
  #       end
  #       @order
  #     else
  #       @order.error_codes
  #     end
  #   end
  # end

  def update
    @order = @current_user.orders.find_by_id(params[:id])
    render_json @order.status == 1 do |s|
      if s
        @order.update_attributes(params[:order])
        @order.as_retval
      else
        ErrorEnum::ORDER_CAN_NOT_BE_UPDATED
      end
    end
  end

  def destroy
    @order = @current_user.orders.find_by_id(params[:id])
    render_json @order.status == 1 do |s|
      if s
        @order.update_attribute("is_deleted", true)
      else
        ErrorEnum::ORDER_CAN_NOT_BE_CANCELED
      end
    end
  end

  def_each :need_verify, :verified, :verify_failed, :delivering, :delivering, :delivered, :deliver_failed do |method_name|
    render_json true do
      #Order.send(method_name).page(page)
      auto_paginate(current_user.orders.send(method_name)) do |orders|
        orders.page(page).per(per_page).map do |o|
          o["gift_name"] = o.gift.name
          o
        end
      end
    end
  end

  def_each :for_cash, :for_entity, :for_virtual, :for_lottery, :for_prize do |method_name|
    render_json true do
      #Order.send(method_name).page(page)
      auto_paginate(current_user.orders.send(method_name)) do |orders|
        orders.page(page).per(per_page).map do |o|
          o["gift_name"] = o.gift.name
          o
        end
      end
    end
  end

end