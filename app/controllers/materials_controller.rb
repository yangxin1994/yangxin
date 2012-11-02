# encoding: utf-8
require 'error_enum'
class MaterialsController < ApplicationController
	before_filter :require_sign_in

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

	#*method*: get
	#
	#*url*: /materials
	#
	#*description*: get a list of materials
	#
	#*params*:
	#* material_type :  a number in the interval [1, 7]. If converted to a binary number, each digit, from the most significant one, indicates images, videos, and audios.
	#
	#*retval*:
	#* the list of objects obtained
	def index
		materials = @current_user.materials.find_by_type(params[:material_type].to_i)
		# File.open("public/a.txt", "w+") do |f|
		# 	f.puts @current_user
		# 	f.puts materials
		# 	#f.puts params[:material_type].to_i
		# end
		flash[:notice] = "成功获取资源列表"
		respond_to do |format|
			format.json	{ render_json_auto(materials) and return }
		end
	end

	#*method*: get
	#
	#*url*: /materials/:material_id
	#
	#*description*: get a material object
	#
	#*params*:
	#* material_id : id of the material to be obtained
	#
	#*retval*:
	#* the Material object
	#* ErrorEnum ::MATERIAL_NOT_EXIST 
	#* ErrorEnum ::UNAUTHORIZED
	def show
		material = @current_user.materials.find_by_id(params[:id])
		case material
		when nil
			flash[:notice] = "该资源不存在"
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::MATERIAL_NOT_EXIST) and return }
			end
		else
			flash[:notice] = "成功获取资源"
			respond_to do |format|
				format.json	{ render_json_auto(material) and return }
			end
		end
	end

	#*method*: delete
	#
	#*url*: /materials/:material_id
	#
	#*description*: destroy a material
	#
	#*params*:
	#* material_id: id of the material to be deleted
	#
	#*retval*:
	#* true: when material is successfully deleted.
	#* ErrorEnum ::MATERIAL_NOT_EXIST : when the material does not exist
	#* ErrorEnum ::UNAUTHORIZED : when the material does not belong to the current user
	def destroy
		material = @current_user.materials.find_by_id(params[:id])
		material.destroy if !material.nil?
		flash[:notice] = "资源已成功删除"
		respond_to do |format|
			format.json	{ render_json_s and return }
		end
	end

	#*method*: put
	#
	#*url*: /materials/:material_id
	#
	#*description*: update title of a material
	#
	#*params*:
	#* material: the material to be updated
	#
	#*retval*:
	#* the material object after updated
	#* ErrorEnum ::MATERIAL_NOT_EXIST : when the material does not exist
	#* ErrorEnum ::UNAUTHORIZED : when the material does not belong to the current user
	def update
		material = @current_user.materials.find_by_id(params[:id])
		if material.nil?
			flash[:notice] = "该资源不存在"
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::MATERIAL_NOT_EXIST) and return }
			end
		end
		retval = material.update_material(params[:material])
		case retval
		when true
			flash[:notice] = "资源标题已成功更新"
			respond_to do |format|
				format.json	{ render_json_auto(material) and return }
			end
		else
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::UNKNOWN_ERROR) and return }
			end
		end
	end
end
