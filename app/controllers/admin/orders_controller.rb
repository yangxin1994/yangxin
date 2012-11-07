class Admin::OrdersController < Admin::ApplicationController
	
	def index
		respond_and_render_json true do
			Order.page(page).per(per_page).map do |o|
				o["gift_name"] = o.gift.name
				logger.info o
				o
			end
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

	def update
		@order = Order.find_by_id(params[:id])
		params[:order][:operated_admin] = current_user
    respond_and_render_json @order.update_attributes(params[:order]) do
      @order.as_retval
    end
	end
	
	def status
		Order.find_by_id params[:id] do |o|
			o.status = params[:status] || o.status
			o.save
		end
	end

	def_each :need_verify, :verified, :verify_failed, :delivering, :delivering, :delivered, :deliver_failed do |method_name|
		respond_and_render_json true do
			#Order.send(method_name).page(page)
			current_user.orders.send(method_name).page(page).per(per_page).map do |o|
				o["gift_name"] = o.gift.name
				logger.info o
				o
			end
		end
	end
	
end