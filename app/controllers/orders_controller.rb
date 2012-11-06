class OrdersController < ApplicationController
#TO DO before_filter
	before_filter :require_user_exist
	def index
		respond_and_render_json { @current_user.orders.page(page) }
	end

	def show
		# TODO is owners request?
		respond_and_render_json { Order.find_by_id(params[:id])}
	end

	def create
		@order = Order.create(params[:order])
		respond_and_render_json @order.save do |s|
			if s
				[:cash_receive_info, :entity_receive_info, :virtual_receive_info, :lottery_receive_info].each do |e| 
					@order.send("create_#{e.to_s}",params[:order][e]) if params[:order].include? e
				end
				@order
			else
				@order.error_codes
			end
		end
	end

	def update
		@order = Order.find_by_id(params[:id])

		respond_to do |format|
			if @order.update_attributes(params[:order])
				format.json { head :ok }
			else
				format.json { render json: @order.errors, status: :unprocessable_entity }
			end
		end
	end
	# def destroy
	# 	@order = Order.find(params[:id])
	# 	@order.destroy

	# 	respond_to do |format|
	# 		format.html { redirect_to orders_url }
	# 		format.json { head :ok }
	# 	end
	# end
	def_each :for_cash, :for_entity, :for_virtual, :for_lottery, :for_award do |method_name|
		@orders = Order.send(method_name).page(params[:page].to_i)
		respond_to do |format|
			format.html 
			format.json { render json: @orders }
		end
	end

end