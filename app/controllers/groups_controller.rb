# encoding: utf-8
require 'error_enum'
class GroupsController < ApplicationController
	before_filter :require_sign_in

	#*method*: get
	#
	#*url": /groups
	#
	#*desciption*: get groups of one user
	#
	#*params*:
	#
	#*params*:
	#* the group array object
	def index
		retval = @current_user.groups
		case retval
		when ErrorEnum::EMAIL_NOT_EXIST
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::EMAIL_NOT_EXIST and return }
			end
		else
			respond_to do |format|
				format.json	{ render :json => retval and return }
			end
		end
	end

	#*method*: post
	#
	#*url": /groups
	#
	#*desciption*: create a new group
	#
	#*params*:
	#* group: a hash which has the following keys
	#  - name: name of the group
	#  - description: description of the group
	#  - members: array of emails for the group
	#
	#*params*:
	#* the group object
	#* ErrorEnum::EMAIL_NOT_EXIST
	#* ErrorEnum::ILLEGAL_EMAIL
	#* ErrorEnum::GROUP_NOT_EXIST
	def create
		members = params[:group]["members"].class == Array ? params[:group]["members"] : []
		sub_groups = params[:group]["sub_groups"].class == Array ? params[:group]["sub_groups"] : []
		retval = @current_user.create_group(params[:group]["name"], params[:group]["description"], members, sub_groups)
		case retval
		when ErrorEnum::EMAIL_NOT_EXIST
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::EMAIL_NOT_EXIST and return }
			end
		when ErrorEnum::ILLEGAL_EMAIL
			flash[:notice] = "非法的邮箱地址"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::ILLEGAL_EMAIL and return }
			end
		when ErrorEnum::GROUP_NOT_EXIST
			flash[:notice] = "样本组不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::GROUP_NOT_EXIST and return }
			end
		else
			flash[:notice] = "样本组已成功创建"
			respond_to do |format|
				format.json	{ render :json => retval and return }
			end
		end
	end

	#*method*: put
	#
	#*url": /groups/:group_id
	#
	#*desciption*: update a group
	#
	#*params*:
	#* group_id: id of the group to be updated
	#* group: the group object to be updated
	#
	#*params*:
	#* the group object
	#* ErrorEnum::GROUP_NOT_EXIST
	#* ErrorEnum::UNAUTHORIZED
	def update
		retval = @current_user.update_group(params[:id], params[:group])
		case retval
		when ErrorEnum::GROUP_NOT_EXIST
			flash[:notice] = "该样本组不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::GROUP_NOT_EXIST and return }
			end
		when ErrorEnum::UNAUTHORIZED
			flash[:notice] = "没有权限"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::UNAUTHORIZED and return }
			end
		when ErrorEnum::ILLEGAL_EMAIL
			flash[:notice] = "非法的邮箱地址"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::ILLEGAL_EMAIL and return }
			end
		when ErrorEnum::GROUP_NOT_EXIST
			flash[:notice] = "样本组不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::GROUP_NOT_EXIST and return }
			end
		else
			flash[:notice] = "样本组已成功更新"
			respond_to do |format|
				format.json	{ render :json => retval and return }
			end
		end
	end

	#*method*: delete
	#
	#*url": /groups/:group_id
	#
	#*desciption*: remove a group
	#
	#*params*:
	#* group_id: id of the group to be deleted
	#
	#*params*:
	#* true if deleted
	#* ErrorEnum::GROUP_NOT_EXIST
	#* ErrorEnum::UNAUTHORIZED
	def destroy
		retval = @current_user.destroy_group(params[:id])
		case retval
		when ErrorEnum::GROUP_NOT_EXIST
			flash[:notice] = "该样本组不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::GROUP_NOT_EXIST and return }
			end
		when ErrorEnum::UNAUTHORIZED
			flash[:notice] = "没有权限"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::UNAUTHORIZED and return }
			end
		else
			flash[:notice] = "样本组已成功删除"
			respond_to do |format|
				format.json	{ render :json => true and return }
			end
		end
	end

	#*method*: get
	#
	#*url": /groups/:group_id
	#
	#*desciption*: get group object
	#
	#*params*:
	#* group_id: id of the group to be obtained
	#
	#*params*:
	#* the group object
	#* ErrorEnum::GROUP_NOT_EXIST
	#* ErrorEnum::UNAUTHORIZED
	def show
		retval = @current_user.show_group(params[:id])
		case retval
		when ErrorEnum::GROUP_NOT_EXIST
			flash[:notice] = "该样本组不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::GROUP_NOT_EXIST and return }
			end
		when ErrorEnum::UNAUTHORIZED
			flash[:notice] = "没有权限"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::UNAUTHORIZED and return }
			end
		else
			respond_to do |format|
				format.json	{ render :json => retval and return }
			end
		end
	end

end
