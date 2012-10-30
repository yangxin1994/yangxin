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
		respond_to do |format|
			if @order = Order.create(params[:order])
				[:cash_receive_info, :realgoods_receive_info, :virtualgoods_receive_info, :lottery_receive_info].each do |e| 
					@order.send("create_#{e.to_s}",params[:order][e]) if params[:order].include? e
				end
				format.json { render json: @order}
			else
				format.json { render json: @order.error_codes }
			end
		end
	end

	def update
		@order = Order.find_by_id(params[:id])

		respond_to do |format|
			if @order.update_attributes(params[:order])
				format.html { redirect_to @order, notice: "updated" }
				format.json { head :ok }
			else
				format.html { render action: "edit" }
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
	def_each :for_cash, :for_realgoods, :for_virtualgoods, :for_lottery, :for_award do |method_name|
		@orders = Order.send(method_name).page(params[:page].to_i)
		respond_to do |format|
			format.html 
			format.json { render json: @orders }
		end
	end

end