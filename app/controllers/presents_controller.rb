class PresentsController < ApplicationController
	# presents.json?page=1
	def index
		@presents = Present.page(params[:page].to_i)
		respond_to do |format|
			format.json { render json: @presents }
		end
	end

	def create
		@present = Present.create(params[:present])
	end

	def update
		@present = Present.find(params[:id])
	end
	
	def show
		@present = Present.find(params[:id])
		if @present
			# TO DO 
		else
			# TO DO
		end
		respond_to do |format|
			format.json { render json: @present}
		end
	end
end
