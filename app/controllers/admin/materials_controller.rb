# encoding: utf-8
require 'securerandom'
require 'error_enum'
class Admin::MaterialsController < Admin::ApplicationController
	def create
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
