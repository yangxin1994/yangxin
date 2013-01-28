class ToolsController < ApplicationController

	def find_provinces
		provinces = Address.find_provinces
		respond_to do |format|
			format.json	{ render_json_s(provinces) and return }
		end
	end

	def find_cities_by_province
		cities = Address.find_cities_by_province(params[:province_code].to_i)
		respond_to do |format|
			format.json	{ render_json_s(cities) and return }
		end
	end

	def find_towns_by_city
		counties = Address.find_towns_by_city(params[:city_code].to_i)
		respond_to do |format|
			format.json	{ render_json_s(counties) and return }
		end
	end

	def find_address_text_by_code
		text = Address.find_province_city_town_by_code(params[:code])
		respond_to do |format|
			format.json	{ render_json_s(text) and return }
		end
	end

	def send_email
		Jobs.start(:EmailSendingJob,
				Time.now.to_i,
				email_type: "normal",
				title: params[:title],
				receiver_list: params[:receiver_list],
				content: params[:content])
	end
end
