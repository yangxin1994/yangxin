# encoding: utf-8
require 'error_enum'
class PagesController < ApplicationController
	before_filter :require_sign_in, :except => [:show]
	before_filter :check_survey_existence

	def check_survey_existence
		@survey = Survey.find_by_id(params[:survey_id])
		render_json_e(ErrorEnum::SURVEY_NOT_EXIST) and return if @survey.nil?
	end

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
		require_sign_in if !@survey.publish_result
		retval = @survey.show_page(params[:id].to_i)
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
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
	#* true
	#* ErrorEnum ::OVERFLOW : when the page index is greater than the page number
	#* ErrorEnum ::SURVEY_NOT_EXIST : when the survey does not exist
	#* ErrorEnum ::UNAUTHORIZED : when the survey does not belong to the current user
	def create
		retval = @survey.create_page(params[:page_index].to_i, params[:page_name])
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end

	def split
		retval = @survey.split_page(params[:id].to_i, params[:question_id], params[:page_name_1], params[:page_name_2])
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end

	def update
		retval = @survey.update_page(params[:id].to_i, params[:page_name])
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end

	#*method*: get
	#
	#*url*: /surveys/:survey_id/pages/:page_index_1/clone
	#
	#*description*: clone a page, and put the new page after the given page
	#
	#*params*:
	#* survey_id: id of the survey
	#* page_index_1: index of the page to be cloned. Page index starts from 0
	#* after_page_index: index of the page, after which the new page is inserted. Page index starts from 0
	#
	#*retval*:
	#* an array of Question object for the cloned page
	#* ErrorEnum ::OVERFLOW : when the page index is greater than the page number
	#* ErrorEnum ::SURVEY_NOT_EXIST : when the survey does not exist
	#* ErrorEnum ::UNAUTHORIZED : when the survey does not belong to the current user
	def clone
		page = @survey.clone_page(params[:id].to_i, params[:after_page_index].to_i)
		respond_to do |format|
			format.json	{ render_json_auto(page) and return }
		end
	end

	#*method*: get
	#
	#*url*: /surveys/:survey_id/pages/:page_index_1/move
	#
	#*description*: clone a page, and put the new page after the given page
	#
	#*params*:
	#* survey_id: id of the survey
	#* page_index_1: index of the page to be moved. Page index starts from 0
	#* after_page_index: index of the page, after which the above page is moved to. Page index starts from 0
	#
	#*retval*:
	#* true: when page is successfully moved
	#* ErrorEnum ::OVERFLOW : when the page index is greater than the page number
	#* ErrorEnum ::SURVEY_NOT_EXIST : when the survey does not exist
	#* ErrorEnum ::UNAUTHORIZED : when the survey does not belong to the current user
	def move
		retval = @survey.move_page(params[:id].to_i, params[:after_page_index].to_i)
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
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
	#* ErrorEnum ::SURVEY_NOT_EXIST : when the survey does not exist
	#* ErrorEnum ::UNAUTHORIZED : when the survey does not belong to the current user
	def destroy
		if params[:enforce].to_s == "true"
			retval = @survey.delete_page!(params[:id].to_i)
		else
			retval = @survey.delete_page(params[:id].to_i)
		end
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end


	#*method*: put
	#
	#*url*: /surveys/:survey_id/pages/:page_index_1/combine
	#
	#*description*: combine continuous pages into one page
	#
	#*params*:
	#* survey_id: id of the survey
	#* page_index_1: the start id of the pages to be combined. Page index starts from 0
	#* after_page_index: the end id of the pages to be combined. Page index starts from 0
	#
	#*retval*:
	#* true: when pages are successfully combined
	#* ErrorEnum ::OVERFLOW : when the page index is greater than the page number
	#* ErrorEnum ::SURVEY_NOT_EXIST : when the survey does not exist
	#* ErrorEnum ::UNAUTHORIZED : when the survey does not belong to the current user
	def combine
		retval = @survey.combine_pages(params[:id].to_i, params[:after_page_index].to_i)
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end
end