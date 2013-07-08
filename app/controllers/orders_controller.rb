class OrdersController < ApplicationController
#TO DO before_filter
  before_filter :require_user_exist
  def index
    render_json true do
      auto_paginate @current_user.orders do |orders|
        orders.map &:present_quillme
      end
    end
  end

  def get_my_orders
    case params[:source]
    when 'priz'
      source = [2]
    when 'gift'
      source = [1,4]
    end
    orders = @current_user.orders.where('source.in' => source).page(params[:pagte]).per(params[:per_page]).desc(:created_at)
    render_json { orders }
  end


  def order_show
    order =  @current_user.orders.find_by_id(params[:id])
    render_json{order}  
  end

  def show
    # TODO is owners request?
    # order =  @current_user.orders.find_by_id(params[:id])
    # render_json order.is_a?(Order) do
    #   order.as_retval
    # end
    @current_user.orders.find_by_id(params[:id]) do |order|
      render_json false do
        success_true
        gift_hash = {"gift" => order.gift || order.prize}
        order.as_retval.attributes.merge(gift_hash)
      end
    end
  end



  def create
    # @gift = Gift.find_by_id(params[:id])
    # render_json @gift.is_valid? &&
    #             @gift.point > current_user.point &&
    #             @gift.surplus >= 0 do |s|
    #   order = params[:order].merge({:gift => @gift, :type => @gift.type})
    #   if s
    #     order = current_user.orders.create(order)
    #     @is_success = false  if order.created_at.nil?
    #     order.as_retval
    #   else
    #     if @gift.surplus <= 0
    #       ErrorEnum::GIFT_NOT_ENOUGH
    #     elsif @gift.point > current_user.point
    #       ErrorEnum::POINT_NOT_ENOUGH
    #     else
    #       ErrorEnum::GIFT_NOT_FOUND
    #     end
    #   end
    # end
    # p @current_user
    # params[:order][:lottery_code_id] = params[:order][:_id] if params[:order][:lottery_code_id].nil?

    @order = @current_user.orders.create(params[:order])
    render_json !@order.deleted? && @order.is_valid? do
      @order.as_retval
    end
  end

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

  def cancel
    render_json do
      result = current_user.orders.find_by_id params[:id] do |o|
        if o.status != 0
          break {
            :error_code => ErrorEnum::ORDER_CAN_NOT_BE_UPDATED,
            :error_message =>  "Order can not be updated"
          }
        end
        o.update_attribute(:status, -2)
        o.gift.inc(:surplus, 1)
        o.lottery_code.update_attribute(:status, 2) if o.lottery_code
        o.update_attribute(:status_desc, params[:status_desc])
        o.reward_log.revoke_operation(current_user, params[:status_desc]) unless o.is_prize
      end
      @is_success = !(result.is_a? Hash)
      result
    end
  end

  def destroy
    @order = @current_user.orders.find_by_id(params[:id])
    render_json @order.status == 0 do |s|
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

  def_each :for_cash, :for_entity, :canceled, :for_virtual, :for_lottery, :for_prize do |method_name|
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