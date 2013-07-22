# encoding: utf-8
class Sample::OrdersController < ApplicationController
	before_filter :require_sign_in

	def index
		@orders = @current_user.orders.where(:source => params[:source])
		@orders_list = auto_paginate(@orders) do |paginated_orders|
			paginated_orders.map { |e| e.info_for_sample }
		end
		logger.info "AAAAAAAAAAAAAAAAAAA"
		logger.info @orders_list.inspect
		logger.info "AAAAAAAAAAAAAAAAAAA"
		render_json_auto @orders_list and return
	end

	def show
		@order = Order.find_by_id(params[:id])
		render_json_e ErrorEnum::ORDER_NOT_EXIST and return if @order.nil?
		render_json_auto @order.info_for_sample_detail and return
	end
end