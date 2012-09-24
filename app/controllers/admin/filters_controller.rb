# encoding: utf-8
require 'error_enum'
class Admin::FiltersController < Admin::ApplicationController
	before_filter :check_normal_survey_existence

	def check_normal_survey_existence
		@survey = Survey.normal.find_by_id(params[:survey_id])
		if @survey.nil?
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::SURVEY_NOT_EXIST) and return }
			end
		end
	end

	#*method*: get
	#
	#*url*: /surveys/:survey_id/filters
	#
	#*description*: list all the filters of a survey
	#
	#*params*:
	#* survey_id: id of the survey
	#
	#*retval*:
	#* an array of filters
	#* ErrorEnum ::SURVEY_NOT_EXIST : when the survey does not exist
	def index
		filters = @survey.list_filters
		respond_to do |format|
			format.json	{ render_json_auto(filters) and return }
		end
	end

	#*method*: get
	#
	#*url*: /surveys/:survey_id/filters/:filter_index
	#
	#*description*: show a filter
	#
	#*params*:
	#* survey_id: id of the survey
	#* filter_index: index of the filter
	#
	#*retval*:
	#* a hash of attributes that represent the filter
	#* ErrorEnum ::SURVEY_NOT_EXIST : when the survey does not exist
	def show
		filter = @survey.show_filter(params[:id].to_i)
		respond_to do |format|
			format.json	{ render_json_auto(filter) and return }
		end
	end

	#*method*: post
	#
	#*url*: /surveys/:survey_id/filters
	#
	#*description*: create a new filter
	#
	#*params*:
	#* survey_id: id of the survey
	#* filter_name: name of the filter to be created
	#* filter_conditions: conditions of the filter to be created
	#
	#*retval*:
	#* the filter object
	#* ErrorEnum ::SURVEY_NOT_EXIST : when the survey does not exist
	#* ErrorEnum ::WRONG_FILTER_CONDITION_TYPE
	def create
		filters = @survey.add_filter(params[:filter_name], params[:filter_conditions])
		respond_to do |format|
			format.json	{ render_json_auto(filter) and return }
		end
	end

	#*method*: put
	#
	#*url*: /surveys/:survey_id/filters/:filter_index
	#
	#*description*: update a filter
	#
	#*params*:
	#* survey_id: id of the survey
	#* filter_index: index of the filter to be updated
	#* filter: the filter to be created
	#
	#*retval*:
	#* the filter object
	#* ErrorEnum ::SURVEY_NOT_EXIST : when the survey does not exist
	#* ErrorEnum ::WRONG_FILTER_CONDITION_TYPE
	#* ErrorEnum ::FILTER_NOT_EXIST
	def update
		filters = @survey.update_filter(params[:id].to_i, params[:filter])
		respond_to do |format|
			format.json	{ render_json_auto(filter) and return }
		end
	end

	def update_filter_name
		filters = @survey.update_filter_name(params[:id].to_i, params[:new_filter_name])
		respond_to do |format|
			format.json	{ render_json_auto(filter) and return }
		end
	end

	#*method*: delete
	#
	#*url*: /surveys/:survey_id/filters/:filter_index
	#
	#*description*: delete a filter
	#
	#*params*:
	#* survey_id: id of the survey
	#* filter_index: index of the filter to be deleted
	#
	#*retval*:
	#* true : when successfully removed
	#* ErrorEnum ::SURVEY_NOT_EXIST : when the survey does not exist
	#* ErrorEnum ::FILTER_NOT_EXIST
	def destroy
		retval = @survey.delete_filter(params[:id].to_i)
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end
end
