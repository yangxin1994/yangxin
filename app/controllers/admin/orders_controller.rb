# encoding: utf-8
class Admin::OrdersController < Admin::ApplicationController
	def index
		@orders = current_user.orders.page(page)
		@orders = ErrorEnum::PresentNotFound if @orders.empty?
		respond_to do |format|
			format.html
			format.json { render json: @orders }
		end
	end
	
	def delete
		@orders = []
		params[:ids].to_a.each do |id|
			@orders << (Order.find_by_id id do |r|
				r.delete
			end)
		end
		respond_to do |format|
			format.json { render json: @orders }
		end
	end

	def operate
		@orders = []
		params[:ids].to_a.each do |id|
			@orders << (Order.find_by_id id do |r|
				r.operate 1
			end)
		end
		respond_to do |format|
			format.json { render json: @orders }
		end
	end

	def_each :need_verify, :verified, :verify_failed, :delivering, :delivering, :delivered, :deliver_failed do |method_name|
		@orders = Order.send(method_name).page(page)
		@orders = ErrorEnum::PresentNotFound if @orders.empty?
		respond_to do |format|
			format.html 
			format.json { render json: @orders }
		end
	end
	
end