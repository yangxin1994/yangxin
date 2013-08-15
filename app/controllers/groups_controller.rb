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
		groups = @current_user.groups
		respond_to do |format|
			format.json	{ render_json_auto(groups) and return }
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
		group = Group.check_and_create_new(params[:group])
		case group
		when ErrorEnum::ILLEGAL_EMAIL
			flash[:notice] = "非法的邮箱地址"
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::ILLEGAL_EMAIL) and return }
			end
		else
			@current_user.groups << group
			flash[:notice] = "样本组已成功创建"
			respond_to do |format|
				format.json	{ render_json_auto(group) and return }
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
		group = @current_user.groups.find_by_id(params[:id])
		if group.nil?
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::GROUP_NOT_EXIST) and return }
			end
		end

		group = group.update_group(params[:group])
		respond_to do |format|
			format.json	{ render_json_auto(group) and return }
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
		group = @current_user.groups.find_by_id(params[:id])
		if group.nil?
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::GROUP_NOT_EXIST) and return }
			end
		end

		@current_user.groups.delete(group)
		retval = group.destroy
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
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
	def show
		group = @current_user.groups.find_by_id(params[:id])
		if group.nil?
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::GROUP_NOT_EXIST) and return }
			end
		end
		respond_to do |format|
			format.json	{ render_json_auto(group) and return }
		end
	end
end