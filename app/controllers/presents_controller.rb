# encoding: utf-8
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
		@presents = Present.can_be_rewarded.page(page) || ErrorEnum::PresentNotFound
		respond_to do |format|
			format.html 
			format.json { render json: @presents }
		end
	end


	def_each :virtual_goods, :cash, :real_goods, :stockout do |method_name|
		@presents = Present.send(method_name).can_be_rewarded.page(page) || ErrorEnum::PresentNotFound
		respond_to do |format|
			format.html 
			format.json { render json: @presents}
		end
	end

	def show
		begin
			retval = Present.find(params[:id])
		rescue Mongoid::Errors::DocumentNotFound
			retval = ErrorEnum::PresentNotFound
		rescue BSON::InvalidObjectId
			retval = ErrorEnum::InvalidPresentId
		end
		respond_to do |format|
			format.json { render json: retval }
		end
	end
end
