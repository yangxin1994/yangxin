# encoding: utf-8
class Sample::OrdersController < ApplicationController
	before_filter :require_sign_in

	def index
		@orders = @current_user.orders.where(:source => params[:source]).desc(:created_at)
		@orders_list = auto_paginate(@orders) do |paginated_orders|
			paginated_orders.map { |e| e.info_for_sample }
		end
		render_json_auto @orders_list and return
	end

	def show
		@order = Order.find_by_id(params[:id])
		render_json_e ErrorEnum::ORDER_NOT_EXIST and return if @order.nil?
		order_object = @order.info_for_sample_detail
		render_json_auto order_object and return
	end

	def create_gift_order
		amount  = params['order'].delete('amount')
		point   = params['order'].delete('point')
		order_t = params['order'].delete('gift_id')
		gift_id = Gift.generate_gift_id(order_t)
		opt     = Gift.generate_opt(params[:order],order_t)
		#synchro  reverver info 
		if params['order']['info_sys'].to_s == 'true'
			@current_user.set_receiver_info(opt)
		end		 	
		render_json_e ErrorEnum::INVALID_GIFT_ID and return unless gift_id
		render_json_auto Order.create_redeem_order(@current_user._id, gift_id, amount, point, opt) and return
	end
end