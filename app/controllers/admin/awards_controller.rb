class Admin::PrizesController < Admin::ApplicationController

	def create
		@prize = Prize.create(params[:prize])
		Material.create(:material => params[:material], :materials => @prize)
		respond_and_render_json @prize.save do
			@prize.as_retval
		end
	end
	
	def stockout
		respond_and_render_json { @prizes }
	end

	def update
		@prize = Prize.find(params[:id])
		respond_and_render_json @prize.update_attributes(params[:prize]) do
			@prize.as_retval
		end
	end

	def delete
		params[:ids] ||= []
		respond_and_render_json do
			params[:ids].to_a.each do |id|
				Prize.find_by_id id do |r|
					r.delete
				end
			end
		end
		# @prizes = []
		# params[:ids].to_a.each do |id|
		# 	@prizes << (Prize.find_by_id id do |r|
		# 		r.delete
		# 	end)
		# end
		# respond_to do |format|
		# 	format.json { render json: @prizes }
		# end
	end


end