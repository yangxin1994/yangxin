# encoding: utf-8
require 'securerandom'
require 'error_enum'
class Admin::MaterialsController < Admin::ApplicationController
	def create
		@material = Material.check_and_create_new(@current_user, params[:material])
		render_json_auto @material and return
	end

	def show
		@material = Material.find_by_id(@material)
		render_json_auto ErrorEnum::MATERIAL_NOT_EXIST and return if !@material.nil?
		render_json_auto @material and return
	end
end
