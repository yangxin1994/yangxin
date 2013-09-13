# finish migrating
class JobsController < ApplicationController

	before_filter :require_sign_in

	# AJAX
	def show
		render_json_auto Result.job_progress(params[:id]) and return
		# render :json => @ws_client.job_progress
	end

	# AJAX
	def data_list
		result = AnalysisResult.get_data_list(params[:id])
		result[:answer_info] = auto_paginate(result[:answer_info])
		# result = @ws_client.get_data_list(params[:page].to_i, params[:per_page].to_i)
		if result[:answer_info].present? && result[:answer_info]['data'].present?
			result[:answer_info]['data'].each do |v|
				v['region_name'] = QuillCommon::AddressUtility.find_text_by_code(v['region'])
			end
		end
		render_json_auto result and return
	end

	# AJAX
	def stats
		retval = AnalysisResult.get_stats(params[:id])
		render_json_auto retval and return
		# render :json => @ws_client.get_stats
	end

	# AJAX
	def analysis_result
		retval = AnalysisResult.get_analysis_result(params[:id], params[:page_index].to_i)
		render_json_auto retval and return
		# render :json => @ws_client.get_analysis_result(params[:page_index].to_i)
	end

	# AJAX
	def file_uri
		render_json_auto Result.get_file_uri(params[:id])
		# render :json => @ws_client.get_file_uri
	end
end