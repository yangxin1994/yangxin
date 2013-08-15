class Admin::ReviewAnswersController < ApplicationController
	
	layout :layout_select
	before_filter :get_client, :is_answer_auditor

	def layout_select
		is_admin ? 'admin_new' : 'answer_auditor'
	end

	def is_answer_auditor
		has_role(4) || has_role(16)
	end

	private :layout_select, :is_answer_auditor

	def get_client
		@client = BaseClient.new(session_info,"")
	end

	#********************
	
	def index
		@surveys = @client._get({page: page, per_page: per_page}, "/answer_auditor/surveys")
		_sign_out and return if @surveys.require_login?

		respond_to do |format|
			format.html
			format.json { render json: @surveys}
		end
	end

	def show
		hash_params = {survey_id: params[:id], page: page, per_page: per_page}

		case params[:scope]
		when 'review_pass'
			hash_params.merge!({status: 3})
		when 'review_reject'
			hash_params.merge!({status: 1, reject_types: [2]})
		when 'system_reject'
			hash_params.merge!({status: 1, reject_types: [0,1,3,4]})
		else
			# 'unreview'
			hash_params.merge!({status: 2})
		end
				
		@answers = @client._get(hash_params, "/answer_auditor/answers")
		_sign_out and return if @answers.require_login?
		respond_to do |format|
			format.html
			format.json { render json: @answers}
		end
	end

	def show_answer
		@answer = @client._get({}, "/answer_auditor/answers/#{params[:answer_id]}")

		if @answer.success
			@address = QuillCommon::AddressUtility.find_province_city_town_by_code(@answer.value['region'])
		end
		
		# sign_out and return if @answer.require_login?
		respond_to do |format|
			format.html
			format.json { render json: @answer}
		end
	end

	def review
		render :json => @client._put({
				review_result: params[:review_result],
				message_content: params[:message_content]
			}, "/answer_auditor/answers/#{params[:answer_id]}/review")		
	end

	def destroy
		# this id is answer_id, not of survey
		render :json => @client._delete({}, "/answer_auditor/answers/#{params[:id]}")	
	end

end