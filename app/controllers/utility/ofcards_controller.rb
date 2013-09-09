require 'error_enum'
class Utility::OfcardsController < ApplicationController
	def confirm
		@order = Order.find_by_id(params[:sporder_id])
		@order.confirm(params[:ret_code]) if !@order.nil?
		render_json_auto true and return
	end 
end
