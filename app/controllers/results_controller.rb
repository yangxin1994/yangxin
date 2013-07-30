class ResultsController < ApplicationController
	before_filter :require_sign_in, :only => [:to_excel, :to_spss]
	before_filter :check_normal_survey_existence, :only => [:analysis, :to_spss, :to_excel, :report]
	before_filter :check_analysis_result_existence, :only => [:to_spss, :to_excel, :report]
	before_filter :check_authority, :except => [:to_excel, :to_spss]

	def check_normal_survey_existence
		@survey = (@current_user.is_admin || @current_user.is_super_admin) ? Survey.normal.find_by_id(params[:survey_id]) : @current_user.surveys.normal.find_by_id(params[:survey_id])
		if @survey.nil?
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::SURVEY_NOT_EXIST) and return }
			end
		end
	end

	def check_analysis_result_existence
		data_list = AnalysisResult.get_data_list(params[:analysis_task_id])
		render_json_e(ErrorEnum::RESULT_NOT_EXIST) and return if data_list == ErrorEnum::RESULT_NOT_EXIST
	end

	def check_authority
		require_sign_in if !@survey.publish_result
	end

	def analysis
		task_id = @survey.analysis(params[:filter_index].to_i, params[:include_screened_answer])
		respond_to do |format|
			format.json	{ render_json_auto(task_id) and return }
		end
	end

	def to_spss
		task_id = @survey.to_spss(params[:analysis_task_id])
		render_json task_id and return
	end

	def to_excel
		task_id = @survey.to_excel(params[:analysis_task_id])
		render_json task_id and return
	end

	def report
		task_id = @survey.report(params[:analysis_task_id], params[:report_mockup_id], params[:report_style], params[:report_type])
		render_json_auto(task_id) and return
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
end
