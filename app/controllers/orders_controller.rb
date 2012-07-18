class OrdersController < ApplicationController
#TO DO before_filter
	def index
		@orders = current_user.orders.page(params[:page].to_i)
		respond_to do |format|
			format.html
			format.json { render json: @orders }
		end
	end

	def create		
		respond_to do |format|
			if @order = Present.create(params[:order])
				format.html { redirect_to :action => 'show',:id => @order.id }
				format.json { render json: @order, status: :created, location: @order }
			else
				format.html { render action: "new" }
				format.json { render json: @order.errors }
			end
		end
	end

	def show
		render_404 unless @order = Order.find(params[:id])
		respond_to do |format|
			format.html 
			format.json { render json: @order }
		end
	end

	def new
		@order = Order.new

		respond_to do |format|
			format.html 
			format.json { render json: @order }
		end
	end

	def edit
		@order = Order.find(params[:id])
		respond_to do |format|
			format.html 
			format.json { render json: @order }
		end
	end

	def update
		@order = Faq.find(params[:id])

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
	def destroy
		@order = Order.find(params[:id])
		@order.destroy

		respond_to do |format|
			format.html { redirect_to orders_url }
			format.json { head :ok }
		end
	end
	def_each :for_cash, :for_realgoods, :for_virtualgoods, :for_lottery, :for_award do |method_name|
		flash[:notice] = "No Order" unless @orders = Order.send(method_name).page(params[:page].to_i)
		respond_to do |format|
			format.html 
			format.json { render json: @orders }
		end
	end

end