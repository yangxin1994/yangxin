require 'securerandom'
# encoding: utf-8
require 'error_enum'
class Interviewer::MaterialsController < Interviewer::ApplicationController

	def create
		material_type = params[:material_type].to_i
		render_json_e(ErrorEnum::WRONG_MATERIAL_TYPE) and return if ![8,16,32].include?(material_type)
		path = "uploads/"
		Dir.mkdir('public/uploads') if !File.directory?('public/uploads')
		case params[:material_type].to_i
		when 8
			path += "images/"
			Dir.mkdir('public/uploads/images') if !File.directory?('public/uploads/images')
		when 16
			path += "videos/"
			Dir.mkdir('public/uploads/videos') if !File.directory?('public/uploads/videos')
		when 32
			path += "audios/"
			Dir.mkdir('public/uploads/audios') if !File.directory?('public/uploads/audios')
		end
		path += SecureRandom.uuid
		File.open("public/#{path}", "wb") { |f| f.write(params[:file].read) }
		material = {"material_type" => params[:material_type],
					"title" => params[:file].original_filename,
					"value" => path}
		material_inst = Material.check_and_create_new(nil, material)
		render_json_auto(material_inst._id.to_s) and return
	end
end
