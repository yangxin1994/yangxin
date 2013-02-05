# encoding: utf-8
require 'error_enum'
class MaterialsController < Interviewer::ApplicationController
	before_filter :require_sign_in, :except => [:show]

	#*method*: post
	#
	#*url*: /materials
	#
	#*description*: create a new material
	#
	#*params*:
	#
	#*retval*:
	#* the new Material object
	#* ErrorEnum::EMAIL_NOT_EXIST
	#* ErrorEnum::WRONG_MATERIAL_TYPE
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
		material = Material.check_and_create_new(@current_user, params[:material])
		case material
		when ErrorEnum::WRONG_MATERIAL_TYPE
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::WRONG_MATERIAL_TYPE) and return }
			end
		else
			flash[:notice] = "资源已成功创建"
			respond_to do |format|
				format.json	{ render_json_auto(material) and return }
			end
		end
	end
end
