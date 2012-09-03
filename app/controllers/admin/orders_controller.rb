# encoding: utf-8
class Admin::OrdersController < Admin::ApplicationController
	
	def index
		respond_and_render_json true do
			current_user.orders.page(page)
		end
	end
	
	def delete
		@orders = []
		params[:ids].to_a.each do |id|
			@orders << (Order.find_by_id id do |r|
				r.delete
			end)
		end
		respond_and_render_json{ @orders }
	end

	def operate
		@orders = []
		params[:ids].to_a.each do |id|
			@orders << (Order.find_by_id id do |r|
				r.operate 1
			end)
		end
		respond_and_render_json{@orders }
	end

	def_each :need_verify, :verified, :verify_failed, :delivering, :delivering, :delivered, :deliver_failed do |method_name|
		respond_and_render_json true, :only => [:type] do
			Order.send(method_name).page(page)
		end
	end
	
end