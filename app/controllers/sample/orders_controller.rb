# finish migrating
require 'error_enum'
class Sample::OrdersController < Sample::SampleController

	before_filter :require_sign_in

	def initialize
		super('gift')
	end

	def create
		amount  = params[:order].delete('amount')
		point   = params[:order].delete('point')
		order_t = params[:order].delete('gift_id')
		gift_id = Gift.generate_gift_id(order_t)
		opt     = Gift.generate_opt(params[:order],order_t)
		#synchro  reverver info 
		if params[:order]['info_sys'].to_s == 'true'
			@current_user.set_receiver_info(opt)
		end		 	
		render_json_e ErrorEnum::INVALID_GIFT_ID and return unless gift_id
		render_json_auto Order.create_redeem_order(@current_user._id, gift_id, amount, point, opt) and return
	end
end