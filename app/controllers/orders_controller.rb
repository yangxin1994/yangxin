class OrdersController < ApplicationController
#TO DO before_filter
	def index
		@orders = current_user.orders.page(params[:page].to_i)
		respond_to do |format|
			format.json { render json: @orders }
		end
	end

	def create		
    respond_to do |format|
      if @order = Present.create(params[:order])
        format.html { redirect_to :action => 'show',:id => @order.id }
        #format.json { render json: @order, status: :created, location: @order }
      else
        format.html { render action: "new" }
        #format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
	end

  def show
    @order = Order.find(params[:id])

    respond _to do |format|
      format.html # show.html.erb
      format.json { render json: @order }
    end
  end

  def new
    @order = Order.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @order }
    end
  end

  def edit
    @order = Order.find(params[:id])
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
	def_each :cash, :realgoods_present, :virtualgoods_present, :lottery_present, :award_present do |method_name|
		flash[:notice] = "No Order" unless @orders = Order.send(method_name).page(params[:page].to_i)
		respond_to do |format|
			format.html 
			format.json { render json: @orders }
		end
	end
	def_each :need_verify, :verified, :verify_failed, :delivering, :delivering, :delivered, :deliver_failed do |method_name|
		flash[:notice] = "No Order" unless @orders = Order.send(method_name).page(params[:page].to_i)
		respond_to do |format|
			format.html 
			format.json { render json: @orders }
		end
	end
end