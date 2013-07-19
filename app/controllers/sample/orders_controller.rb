# encoding: utf-8
class Sample::OrdersController < ApplicationController
	before_filter :require_sign_in

	def index
		@orders = @current_user.orders.where(:source => params[:source])
		@orders_list = auto_paginate(@orders) do |paginated_orders|
			paginated_orders.map { |e| e.info_for_sample }
		end
		render_json_auto @orders_list and return
	end

	def show
		@order = Order.find_by_id(params[:id])
		render_json_auto @order.info_for_sample_detail and return
	end
end