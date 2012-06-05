# encoding: utf-8
require 'error_enum'
class MaterialsController < ApplicationController
	before_filter :require_sign_in

	def show
	end
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
		retval = @current_user.create_material(params[:material]["material_type"].to_i, params[:material]["location"], params[:material]["title"])
		case retval
		when ErrorEnum::EMAIL_NOT_EXIST
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::EMAIL_NOT_EXIST and return }
			end
		else
			flash[:notice] = "资源已成功创建"
			respond_to do |format|
				format.json	{ render :json => retval and return }
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
		retval = @current_user.get_material_object_list(params[:material_type].to_i)
		case retval
		when ErrorEnum::WRONG_MATERIAL_TYPE
			flash[:notice] = "错误的资源类型"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::WRONG_MATERIAL_TYPE and return }
			end
		else
			flash[:notice] = "成功获取资源列表"
			respond_to do |format|
				format.json	{ render :json => retval and return }
			end
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
		retval = @current_user.get_material_object(params[:id])
		case retval
		when ErrorEnum::MATERIAL_NOT_EXIST
			flash[:notice] = "该资源不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::MATERIAL_NOT_EXIST and return }
			end
		when ErrorEnum::UNAUTHORIZED
			flash[:notice] = "没有权限"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::UNAUTHORIZED and return }
			end
		else
			flash[:notice] = "成功获取资源"
			respond_to do |format|
				format.json	{ render :json => retval and return }
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
		retval = @current_user.destroy_material(params[:id])
		case retval
		when ErrorEnum::MATERIAL_NOT_EXIST
			flash[:notice] = "该资源不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::MATERIAL_NOT_EXIST and return }
			end
		when ErrorEnum::UNAUTHORIZED
			flash[:notice] = "没有权限"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::UNAUTHORIZED and return }
			end
		else
			flash[:notice] = "资源已成功删除"
			respond_to do |format|
				format.json	{ render :json => true and return }
			end
		end
	end

	#*method*: get
	#
	#*url*: /materials/:material_id/clear
	#
	#*description*: thoroughly delete a material
	#
	#*params*:
	#* material_id: id of the material to be cleared
	#
	#*retval*:
	#* true: when material is successfully cleared.
	#* ErrorEnum ::MATERIAL_NOT_EXIST : when the material does not exist
	#* ErrorEnum ::UNAUTHORIZED : when the material does not belong to the current user
	def clear
		retval = @current_user.clear_material(params[:id])
		case retval
		when ErrorEnum::MATERIAL_NOT_EXIST
			flash[:notice] = "该资源不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::MATERIAL_NOT_EXIST and return }
			end
		when ErrorEnum::UNAUTHORIZED
			flash[:notice] = "没有权限"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::UNAUTHORIZED and return }
			end
		else
			flash[:notice] = "资源已成功清除"
			respond_to do |format|
				format.json	{ render :json => true and return }
			end
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
		retval = @current_user.update_material_title(params[:id], params[:material])
		case retval
		when ErrorEnum::MATERIAL_NOT_EXIST
			flash[:notice] = "该资源不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::MATERIAL_NOT_EXIST and return }
			end
		when ErrorEnum::UNAUTHORIZED
			flash[:notice] = "没有权限"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::UNAUTHORIZED and return }
			end
		else
			flash[:notice] = "资源标题已成功更新"
			respond_to do |format|
				format.json	{ render :json => retval and return }
			end
		end
	end
end
