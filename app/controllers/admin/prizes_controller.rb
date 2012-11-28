class Admin::PrizesController < Admin::ApplicationController

	def create
		@prize = Prize.create(params[:prize])
		Material.create(:material => params[:material], :materials => @prize)
		render_json @prize.save do
			@prize.as_retval
		end
	end
	
	def stockout
		render_json { @prizes }
	end

	def update
		@prize = Prize.find(params[:id])
		render_json @prize.update_attributes(params[:prize]) do
			@prize.as_retval
		end
	end

	def delete
		params[:ids] ||= []
		render_json do
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

	def for_lottery
		render_json do
			Prize.for_lottery
		end
	end

end