# encoding: utf-8
require 'error_enum'
class PagesController < ApplicationController
	before_filter :require_sign_in

	#*method*: get
	#
	#*url*: /surveys/:survey_id/pages/:page_index
	#
	#*description*: obtain a page of a survey. the page consists of an array of Question object
	#
	#*params*:
	#* survey_id: id of the survey
	#* page_index: index of this page in this survey. Page index starts from 0
	#
	#*retval*:
	#* an array of Question object: when page is successfully obtained
	#* ErrorEnum ::OVERFLOW : when the page index is greater than the page number
	#* ErrorEnum ::SURVEY_NOT_EXIST : when the survey does not exist
	#* ErrorEnum ::UNAUTHORIZED : when the survey does not belong to the current user
	def show
		retval = @current_user.show_page(params[:survey_id], params[:page_index].to_i)
		case retval
		when ErrorEnum::SURVEY_NOT_EXIST
			flash[:notice] = "该调查问卷不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::SURVEY_NOT_EXIST and return }
			end
		when ErrorEnum::OVERFLOW
			flash[:notice] = "页码溢出"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::OVERFLOW and return }
			end
		when ErrorEnum::UNAUTHORIZED
			flash[:notice] = "没有权限"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::UNAUTHORIZED and return }
			end
		else
			flash[:notice] = "成功获取页面"
			respond_to do |format|
				format.json	{ render :json => retval and return }
			end
		end
	end


	#*method*: post
	#
	#*url*: /surveys/:survey_id/pages
	#
	#*description*: create a new empty page after the given page
	#
	#*params*:
	#* survey_id: id of the survey
	#* page_index: index of this page, after which the new page is created, if set -1, new page is insert at the beginning of the survey. Page index starts from 0
	#
	#*retval*:
	#* an array of Question object: when page is successfully obtained
	#* ErrorEnum ::OVERFLOW : when the page index is greater than the page number
	#* ErrorEnum ::NOT_EXIST : when the survey does not exist
	#* ErrorEnum ::UNAUTHORIZED : when the survey does not belong to the current user
	def create
		retval = @current_user.create_page(params[:survey_id], params[:page_index].to_i)
		case retval
		when ErrorEnum::SURVEY_NOT_EXIST
			flash[:notice] = "该调查问卷不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::SURVEY_NOT_EXIST and return }
			end
		when ErrorEnum::OVERFLOW
			flash[:notice] = "页码溢出"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::OVERFLOW and return }
			end
		when ErrorEnum::UNAUTHORIZED
			flash[:notice] = "没有权限"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::UNAUTHORIZED and return }
			end
		else
			flash[:notice] = "成功创建新页面"
			respond_to do |format|
				format.json	{ render :json => retval and return }
			end
		end
	end

	#*method*: get
	#
	#*url*: /surveys/:survey_id/pages/:page_index/clone
	#
	#*description*: clone a page, and put the new page after the given page
	#
	#*params*:
	#* survey_id: id of the survey
	#* page_index_1: index of the page to be cloned. Page index starts from 0
	#* page_index_2: index of the page, after which the new page is inserted. Page index starts from 0
	#
	#*retval*:
	#* an array of Question object for the cloned page
	#* ErrorEnum ::OVERFLOW : when the page index is greater than the page number
	#* ErrorEnum ::NOT_EXIST : when the survey does not exist
	#* ErrorEnum ::UNAUTHORIZED : when the survey does not belong to the current user
	def clone
		retval = @current_user.clone_page(params[:survey_id], params[:page_index_1].to_i, params[:page_index_2].to_i)
		case retval
		when ErrorEnum::SURVEY_NOT_EXIST
			flash[:notice] = "该调查问卷不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::SURVEY_NOT_EXIST and return }
			end
		when ErrorEnum::OVERFLOW
			flash[:notice] = "页码溢出"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::OVERFLOW and return }
			end
		when ErrorEnum::UNAUTHORIZED
			flash[:notice] = "没有权限"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::UNAUTHORIZED and return }
			end
		else
			flash[:notice] = "成功复制页面"
			respond_to do |format|
				format.json	{ render :json => retval and return }
			end
		end
	end

	#*method*: get
	#
	#*url*: /surveys/:survey_id/pages/:page_index_1/:page_index_2/move
	#
	#*description*: clone a page, and put the new page after the given page
	#
	#*params*:
	#* survey_id: id of the survey
	#* page_index_1: index of the page to be moved. Page index starts from 0
	#* page_index_2: index of the page, after which the above page is moved to. Page index starts from 0
	#
	#*retval*:
	#* 1: when page is successfully moved
	#* ErrorEnum ::OVERFLOW : when the page index is greater than the page number
	#* ErrorEnum ::NOT_EXIST : when the survey does not exist
	#* ErrorEnum ::UNAUTHORIZED : when the survey does not belong to the current user
	def move
		retval = @current_user.move_page(params[:survey_id], params[:page_index_1].to_i, params[:page_index_2].to_i)
		case retval
		when ErrorEnum::SURVEY_NOT_EXIST
			flash[:notice] = "该调查问卷不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::SURVEY_NOT_EXIST and return }
			end
		when ErrorEnum::OVERFLOW
			flash[:notice] = "页码溢出"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::OVERFLOW and return }
			end
		when ErrorEnum::UNAUTHORIZED
			flash[:notice] = "没有权限"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::UNAUTHORIZED and return }
			end
		else
			flash[:notice] = "成功移动页面"
			respond_to do |format|
				format.json	{ render :json => retval and return }
			end
		end
	end

	#*method*: delete
	#
	#*url*: /surveys/:survey_id/pages/:page_index
	#
	#*description*: delete a page
	#
	#*params*:
	#* survey_id: id of the survey
	#* page_index: the id of the page to be deleted. Page index starts from 0
	#
	#*retval*:
	#* 1: when page is successfully destroyed
	#* ErrorEnum ::OVERFLOW : when the page index is greater than the page number
	#* ErrorEnum ::NOT_EXIST : when the survey does not exist
	#* ErrorEnum ::UNAUTHORIZED : when the survey does not belong to the current user
	def destroy
		retval = @current_user.delete_page(params[:survey_id], params[:page_index].to_i)
		case retval
		when ErrorEnum::SURVEY_NOT_EXIST
			flash[:notice] = "该调查问卷不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::SURVEY_NOT_EXIST and return }
			end
		when ErrorEnum::OVERFLOW
			flash[:notice] = "页码溢出"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::OVERFLOW and return }
			end
		when ErrorEnum::UNAUTHORIZED
			flash[:notice] = "没有权限"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::UNAUTHORIZED and return }
			end
		else
			flash[:notice] = "成功删除页面"
			respond_to do |format|
				format.json	{ render :json => retval and return }
			end
		end
	end


	#*method*: get
	#
	#*url*: /surveys/:survey_id/pages/:page_index_1/:page_index_2/combine
	#
	#*description*: combine continuous pages into one page
	#
	#*params*:
	#* survey_id: id of the survey
	#* page_index_1: the start id of the pages to be combined. Page index starts from 0
	#* page_index_2: the end id of the pages to be combined. Page index starts from 0
	#
	#*retval*:
	#* 1: when page is successfully destroyed
	#* ErrorEnum ::OVERFLOW : when the page index is greater than the page number
	#* ErrorEnum ::NOT_EXIST : when the survey does not exist
	#* ErrorEnum ::UNAUTHORIZED : when the survey does not belong to the current user
	def combine
		retval = @current_user.combine_pages(params[:survey_id], params[:page_index_1].to_i, params[:page_index_2].to_i)
		case retval
		when ErrorEnum::SURVEY_NOT_EXIST
			flash[:notice] = "该调查问卷不存在"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::SURVEY_NOT_EXIST and return }
			end
		when ErrorEnum::OVERFLOW
			flash[:notice] = "页码溢出"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::OVERFLOW and return }
			end
		when ErrorEnum::UNAUTHORIZED
			flash[:notice] = "没有权限"
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::UNAUTHORIZED and return }
			end
		else
			flash[:notice] = "成功合并页面"
			respond_to do |format|
				format.json	{ render :json => retval and return }
			end
		end
	end

end
