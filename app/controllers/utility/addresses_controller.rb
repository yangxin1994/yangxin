class Utility::AddressesController < ApplicationController
	
	def provinces
		render :json => QuillCommon::AddressUtility.find_provinces
	end

	def cities
		render :json => QuillCommon::AddressUtility.find_cities_by_province(params[:province_id].to_i)
	end

	def towns
		render :json => QuillCommon::AddressUtility.find_towns_by_city(params[:city_id].to_i)
	end

end