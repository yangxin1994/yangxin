class Sample::OrdersController < Sample::SampleController

	before_filter :require_sign_in,:except => [:create_lottery_order]

	def initialize
		super('gift')
	end

	def index
		@orders = Sample::OrderClient.new(session_info).index(params[:page], 10)
		@orders.success ? @orders = @orders.value : @orders = nil
		if !@orders.nil? && !@orders['data'].nil?
			@orders['data'].each do |o|
				_get_order_gift!(o)
			end
		end
	end

	def show
		@order = Sample::OrderClient.new(session_info).show(params[:id])
		respond_to do |format|
			format.html do
				logger.debug @order.success
				@order.success ? @order = @order.value : @order = nil
				@order[:is_prize] ? _get_order_prize!(@order) : _get_order_gift!(@order)
			end
			format.json { render :json => @order and return }
		end
	end

	def cancel
		render :json => Sample::OrderClient.new(session_info).cancel(params[:id])
	end

	def create
		render :json => Sample::OrderClient.new(session_info).create(params[:order])
	end

	def create_lottery_order
		render :json => Sample::OrderClient.new(session_info).create_lottery_order(params[:order_info])
	end

	def destroy
		render :json => Sample::OrderClient.new(session_info).delete(params[:id])
	end

	private
	def _get_order_gift!(order)
		return if order.nil?
		result = Sample::GiftClient.new(session_info).show(order['gift_id'])
		order['gift'] = result.value if result.success
	end
	def _get_order_prize!(order)
		return if order.nil?
		result = Sample::PrizeClient.new(session_info).show(order['gift_id'])
		order['gift'] = result.value if result.success
	end
end