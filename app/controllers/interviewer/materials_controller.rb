# encoding: utf-8
require 'error_enum'
class Interviewer::MaterialsController < Interviewer::ApplicationController

	def create
		material_type = params[:material_type].to_i
		render_json_e(ErrorEnum::WRONG_MATERIAL_TYPE) if [8,16,32].include?(material_type)
		path = "public/uploads/"
		case params[:material_type]
		when 8
			path += "images/"
		when 16
			path += "videos/"
		when 32
			path += "audios/"
		end
	end
end
