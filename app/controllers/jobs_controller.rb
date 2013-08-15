class JobsController < ApplicationController

	before_filter :require_sign_in, :get_ws_client

	def get_ws_client
		@ws_client = JobClient.new(session_info, params[:id])
	end

	# AJAX
	def show
		render :json => @ws_client.job_progress
	end

	# AJAX
	def data_list
		result = @ws_client.get_data_list(params[:page].to_i, params[:per_page].to_i)
		if result.success && !result.value['answer_info'].blank? && !result.value['answer_info']['data'].blank?
			result.value['answer_info']['data'].each do |v|
				v['region_name'] = QuillCommon::AddressUtility.find_text_by_code(v['region'])
			end
		end
		render :json => result
	end

	# AJAX
	def stats
		render :json => @ws_client.get_stats
	end

	# AJAX
	def analysis_result
		render :json => @ws_client.get_analysis_result(params[:page_index].to_i)
	end

	# AJAX
	def file_uri
		render :json => @ws_client.get_file_uri
	end

end