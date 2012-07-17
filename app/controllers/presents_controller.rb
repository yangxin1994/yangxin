class PresentsController < ApplicationController
	#TO DO before_filter
	# presents.json?page=1

	#*method*: get
	#
	#*url*: /presents
	#
	#*description*: list all presents can be rewarded
	#
	#*params*:
	#* page: page number
	#
	#*retval*:
	#* the Survey object: when meta data is successfully saved.
	#* ErrorEnum ::SURVEY_NOT_EXIST : when the survey does not exist
	#* ErrorEnum ::UNAUTHORIZED : when the survey does not belong to the current user

	def index
		@presents = Present.can_be_rewarded.page(params[:page].to_i)
		respond_to do |format|
			format.html 
			format.json { render json: @presents, :only => [:id, :name, :point, :quantity, :created_at, :status] }
		end
	end


	def_each :virtual_goods, :cash, :real_goods, :stockout do |method_name|
		@present = Present.new
		flash[:notice] = "No Goods" unless @presents = Present.send(method_name).can_be_rewarded.page(params[:page].to_i)
		respond_to do |format|
			format.html 
			format.json { render json: @presents, :only => [:id, :name, :point, :quantity, :created_at, :status]  }
		end
	end

	def show
		@present = Present.find(params[:id])
		respond_to do |format|
			format.json { render json: @present}
		end
	end
end
