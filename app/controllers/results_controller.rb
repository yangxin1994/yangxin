#encoding: utf-8

class ResultsController < ApplicationController
	before_filter :require_sign_in
	before_filter :check_normal_survey_existence, :except => [:job_progress]

	def check_normal_survey_existence
		@survey = @current_user.is_admin ? Survey.normal.find_by_id(params[:survey_id]) : @current_user.surveys.normal.find_by_id(params[:survey_id])
		if @survey.nil?
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::SURVEY_NOT_EXIST) and return }
			end
		end
	end

	def data_list
		job_id = @survey.data_list(params[:id], params[:include_screened_answer])
		respond_to do |format|
			format.json	{ render_json_auto(job_id) and return }
		end
	end

  def analysis
		job_id = @survey.analysis(params[:id], params[:include_screened_answer])
		respond_to do |format|
			format.json	{ render_json_auto(job_id) and return }
		end
  end

	def job_progress
		progress = Result.job_progress(params[:job_id])
		if progress == 1
			result = Result.find_result_by_job_id(params[:job_id])
			respond_to do |format|
				format.json	{ render_json_auto(result) and return }
			end
		else
			respond_to do |format|
				format.json	{ render_json_s(progress) and return }
			end
		end
	end

	def check_progress
		retval = @survey.check_progress(params[:detail])
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end

	def to_spss
		data_list_result = Result.find_result_by_job_id(params[:job_id])

		export_result = ExportResult.find_or_create_by_result_key(data_list_result.result_key, @survey)
		if export_result.is_export_spss_finished
      "Spss文件的路径:类似于 localhost/result_key.sav"
    else
    	job_id = Jobs::ToSpssJob.create(:export_result_id => export_result.id)
    end

	end


end
