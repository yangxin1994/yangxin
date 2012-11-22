class ResultsController < ApplicationController
	before_filter :require_sign_in
	before_filter :check_normal_survey_existence, :except => [:job_progress]

	def check_normal_survey_existence
		@survey = (@current_user.is_admin || @current_user.is_super_admin) ? Survey.normal.find_by_id(params[:survey_id]) : @current_user.surveys.normal.find_by_id(params[:survey_id])
		if @survey.nil?
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::SURVEY_NOT_EXIST) and return }
			end
		end
	end

	def data_list
		job_id = @survey.data_list(params[:filter_index].to_i, params[:include_screened_answer])
		respond_to do |format|
			format.json	{ render_json_auto(job_id) and return }
		end
	end

	def to_spss
		data_list_result = Result.find_by_result_key(params[:result_key])
		render_json !data_list_result.nil? do 
			if data_list_result.nil?
				ErrorEnum::DATA_LIST_NOT_EXIST
			else
				Jobs::ToSpssJob.create(:data_list_result_id => data_list_result.id, :survey_id => @survey.id)
			end
		end
	end

	def to_excel
		data_list_result = Result.find_by_result_key(params[:result_key])
		render_json !data_list_result.nil? do |e|
			if !e
				ErrorEnum::DATA_LIST_NOT_EXIST
			else
				Jobs::ToExcelJob.create(:data_list_result_id => data_list_result.id, :survey_id => @survey.id)
			end
		end
	end

	def analysis
		job_id = @survey.analysis(params[:filter_index].to_i, params[:include_screened_answer])
		respond_to do |format|
			format.json	{ render_json_auto(job_id) and return }
		end
	end

	def report
		job_id = @survey.report(params[:filter_index].to_i, params[:include_screened_answer], params[:report_mockup_id], params[:report_style], params[:report_type])
		respond_to do |format|
			format.json	{ render_json_auto(job_id) and return }
		end
	end

	def job_progress
		progress = Result.job_progress(params[:job_id])
		if progress == 1
			result = Result.find_result_by_task_id(params[:job_id])
			logger.info result.inspect
			respond_to do |format|
				# make pagination for data list
				if result["answer_info"] && !result["answer_info"].blank?
					result["answer_info"] = auto_paginate result["answer_info"] do |a|
						a.slice((page - 1) * per_page, per_page)
					end
				end
				format.json	{ render_json_auto({ "progress" => 1, "result" => result}) and return }
			end
		else
			respond_to do |format|
				format.json	{ render_json_s({ "progress" => progress }) and return }
			end
		end
	end

	def check_progress
		retval = @survey.check_progress(params[:detail])
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end

	def finish
		result = Result.find_by_result_key params[:result_key]
		result.status = params[:status]
		render_json { result.save }
	end
	
end
