# encoding: utf-8
require 'error_enum'
class ResourcesController < ApplicationController
	before_filter :require_sign_in

	#*method*: post
	#
	#*url*: /resources
	#
	#*description*: create a new resource
	#
	#*params*:
	#
	#*retval*:
	#* the new Resource object
	def create
		retval = @current_user.create_resource(params[:resource])
		respond_to do |format|
			format.json	{ render :json => retval and return }
		end
	end

	#*method*: get
	#
	#*url*: /resources
	#
	#*description*: get a list of resources
	#
	#*params*:
	#* resource_type : can be 0 (images), 1 (videos), or 2 (audios)
	#
	#*retval*:
	#* id of the new resource
	#* ErrorEnum ::WRONG_RESOURCE_TYPE
	def index
		retval = @current_user.get_resource_object_list(params[:resource_type])
		case retval
		when ErrorEnum::WRONG_RESOURCE_TYPE
			flash[:notice] = "错误的资源类型"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::WRONG_RESOURCE_TYPE and return }
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
	#*url*: /resources/:resource_id
	#
	#*description*: get a resource object
	#
	#*params*:
	#* resource_id : id of the resource to be obtained
	#
	#*retval*:
	#* the Resource object
	#* ErrorEnum ::RESOURCE_NOT_EXIST 
	#* ErrorEnum ::UNAUTHORIZED
	def show
		retval = @current_user.get_resource_object(params[:resource_id])
		case retval
		when ErrorEnum::RESOURCE_NOT_EXIST
			flash[:notice] = "该资源不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::RESOURCE_NOT_EXIST and return }
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
	#*url*: /resources/:resource_id
	#
	#*description*: destroy a resource
	#
	#*params*:
	#* resource_id: id of the resource to be deleted
	#
	#*retval*:
	#* true: when resource is successfully deleted.
	#* ErrorEnum ::RESOURCE_NOT_EXIST : when the resource does not exist
	#* ErrorEnum ::UNAUTHORIZED : when the resource does not belong to the current user
	def destroy
		retval = @current_user.destroy_resource(params[:id])
		case retval
		when ErrorEnum::RESOURCE_NOT_EXIST
			flash[:notice] = "该资源不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::RESOURCE_NOT_EXIST and return }
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
	#*url*: /resources/:resource_id/clear
	#
	#*description*: thoroughly delete a resource
	#
	#*params*:
	#* resource_id: id of the resource to be cleared
	#
	#*retval*:
	#* true: when resource is successfully cleared.
	#* ErrorEnum ::RESOURCE_NOT_EXIST : when the resource does not exist
	#* ErrorEnum ::UNAUTHORIZED : when the resource does not belong to the current user
	def clear
		retval = @current_user.clear_resource(params[:id])
		case retval
		when ErrorEnum::RESOURCE_NOT_EXIST
			flash[:notice] = "该资源不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::RESOURCE_NOT_EXIST and return }
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
	#*url*: /resources/:resource_id
	#
	#*description*: update title of a resource
	#
	#*params*:
	#* resource: the resource to be updated
	#
	#*retval*:
	#* the resource object after updated
	#* ErrorEnum ::RESOURCE_NOT_EXIST : when the resource does not exist
	#* ErrorEnum ::UNAUTHORIZED : when the resource does not belong to the current user
	def update
		retval = @current_user.update_resource_title(params[:resource])
		case retval
		when ErrorEnum::RESOURCE_NOT_EXIST
			flash[:notice] = "该资源不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::RESOURCE_NOT_EXIST and return }
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
