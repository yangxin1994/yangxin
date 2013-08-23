# finish migrating
require 'error_enum'
class Sample::OrdersController < Sample::SampleController

	before_filter :require_sign_in, :except => [:create_lottery_order]

	def initialize
		super('gift')
	end

	def create
		amount  = params[:order].delete('amount')
		point   = params[:order].delete('point')
		order_t = params[:order].delete('gift_id')
		gift_id = Gift.generate_gift_id(order_t)
		opt     = Gift.generate_opt(params[:order],order_t)
		if params[:order]['info_sys'].to_s == 'true'
			@current_user.set_receiver_info(opt)
		end		 	
		render_json_e ErrorEnum::INVALID_GIFT_ID and return unless gift_id
		render_json_auto Order.create_redeem_order(@current_user._id, gift_id, amount, point, opt) and return
	end

	def create_lottery_order
		@answer = Answer.find_by_id(params[:order_info][:answer_id])
		render_json_e ErrorEnum::ANSWER_NOT_EXIST and return if @answer.nil?
		retval = @answer.create_lottery_order(params[:order_info])
		render_json_auto retval and return
	end
end