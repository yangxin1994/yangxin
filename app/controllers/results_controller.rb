class ResultsController < ApplicationController
	before_filter :require_sign_in
	before_filter :check_normal_survey_existence, :only => [:analysis, :to_spss, :to_excel, :report]

	def check_normal_survey_existence
		@survey = (@current_user.is_admin || @current_user.is_super_admin) ? Survey.normal.find_by_id(params[:survey_id]) : @current_user.surveys.normal.find_by_id(params[:survey_id])
		if @survey.nil?
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::SURVEY_NOT_EXIST) and return }
			end
		end
	end

	def analysis
		task_id = @survey.analysis(params[:filter_index].to_i, params[:include_screened_answer])
		respond_to do |format|
			format.json	{ render_json_auto(task_id) and return }
		end
	end

	def to_spss
		task_id = @survey.to_spss(params[:data_list_key])
		render_json task_id
	end

	def to_excel
		task_id = @survey.to_spss(params[:data_list_key])
		task_id = @survey.to_excel(params[:data_list_key])
		render_json task_id
	end

	def report
		# task_id = @survey.report(params[:filter_index].to_i, params[:include_screened_answer], params[:report_mockup_id], params[:report_style], params[:report_type])
		task_id = @survey.report(params[:data_list_key], params[:report_mockup_id], params[:report_style], params[:report_type])
		respond_to do |format|
			format.json	{ render_json_auto(task_id) and return }
		end
	end

	def job_progress
		progress = Result.job_progress(params[:task_id])
		render_json_auto(progress) and return
	end

	def get_data_list
		result = AnalysisResult.get_data_list(params[:task_id])
		result[:answer_info] = auto_paginate(result[:answer_info])
		render_json_auto(result) and return
	end

	def get_stats
		stats = AnalysisResult.get_stats(params[:task_id])
		render_json_auto(stats) and return
	end

	def get_analysis_result
		analysis_result = AnalysisResult.get_analysis_result(params[:task_id], params[:page_index].to_i)
		render_json_auto(analysis_result) and return
	end

	def get_file_uri
		file_uri = Result.get_file_uri(params[:task_id])
		render_json_auto(file_uri) and return
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
