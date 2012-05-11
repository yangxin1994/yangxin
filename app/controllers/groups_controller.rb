# encoding: utf-8
require 'error_enum'
class GroupsController < ApplicationController
	before_filter :require_sign_in

	# method: get
	# desciption: get all groups of one user
	def index
		respond_to do |format|
			format.json	{ render :json => @current_user.groups.to_json and return }
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
	#  - name: description of the group
	#  - members: description of the group
	#
	def create
		retval = @current_user.create_group(params[:group]["name"], params[:group]["description"], params[:group]["members"])
		case retval
		when ErrorEnum::GROUP_EXIST
			flash[:notice] = "该样本组已经存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::GROUP_EXIST and return }
			end
		else
			flash[:notice] = "样本组已成功创建"
			respond_to do |format|
				format.json	{ render :json => true and return }
			end
		end
	end

	# method: put
	# description: update a group
	def update
		retval = @current_user.update_group(params[:id], params[:group]["new_name"], params[:group]["description"], params[:group]["members"])
		case retval
		when ErrorEnum::GROUP_NOT_EXIST
			flash[:notice] = "该样本组不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::GROUP_NOT_EXIST and return }
			end
		else
			flash[:notice] = "样本组已成功更新"
			respond_to do |format|
				format.json	{ render :json => true and return }
			end
		end
	end

	# method: delete
	# description: remove a group
	def destroy
		retval = @current_user.destroy_group(params[:id])
		case retval
		when ErrorEnum::GROUP_NOT_EXIST
			flash[:notice] = "该样本组不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::GROUP_NOT_EXIST and return }
			end
		else
			flash[:notice] = "样本组已成功删除"
			respond_to do |format|
				format.json	{ render :json => true and return }
			end
		end
	end

	# method: get
	# description: show a group
	def show
		retval = @current_user.show_group(params[:id])
		case retval
		when ErrorEnum::GROUP_NOT_EXIST
			flash[:notice] = "该样本组不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::GROUP_NOT_EXIST and return }
			end
		else
			respond_to do |format|
				format.json	{ render :json => retval.to_json and return }
			end
		end
	end

end
