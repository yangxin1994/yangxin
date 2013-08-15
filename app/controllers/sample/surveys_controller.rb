class Sample::SurveysController < Sample::SampleController

	layout :resolve_layout

  	before_filter :get_client
	def initialize
		super('survey')
	end

	# PAGE
	def index
		@surveys  = @client.get_recommend_list(params[:page],10,nil,params[:status],params[:reward_type],params[:answer_status])
		@surveys  = @surveys.success ?  @surveys.value  : nil
		
		@answer_count   = @answer.get_answer_count
		@answer_count   = @answer_count.success ? @answer_count.value  : nil
		@spread_count   = @answer.get_spread_count    
		@spread_count   = @spread_count.success ? @spread_count.value  : nil
		@disciplinal    = Sample::LogClient.new(session_info).get_disciplinal_news
		@disciplinal    = @disciplinal.success ? @disciplinal.value  : nil
		@reward_count   = @client.get_reward_type_count(params[:status])
		@reward_count   = @reward_count.success ? @reward_count.value : nil
		@fresh_news     = Sample::LogClient.new(session_info).get_fresh_news_list(3,1) 
		@fresh_news     = @fresh_news.success ? @fresh_news.value : nil      
		@status         =  2
	end

	# def get_special_status_surveys
	#   @status = params[:status].present? ? params[:status] : 2
	#   @reward_type = params[:reward_type]
	#   @surveys  = @client.get_recommend_list(params[:page],10,@status,@reward_type)
	#   @surveys  = @surveys.success ?  @surveys.value  : nil
	# end

	def get_reward_type_count
		@reward_count   = @client.get_reward_type_count(params[:status])
		@reward_count = @reward_count.value.length > 0 ?  @reward_count.value : nil
		render :json => @reward_count 
	end

	#重新生成订阅 短信激活码  或者邮件
	def make_rss_activate
		@retval = @client.make_rss_activate(params[:rss_channel],"#{request.protocol}#{request.host_with_port}/surveys/active_rss_able")	
		render :json => @retval.value
	end


	def make_rss_mobile_activate
		@retval = @client.make_rss_mobile_activate(params[:rss_channel],params[:code])		
		render :json => @retval.success
	end

	#订阅邮件 callback链接
	def active_rss_able
		retval = @client.active_rss_able(params[:key])
		account =  Sample::UserClient.new(session_info).get_account(params[:key])
    @email  = account.value

		if retval.success
			@success = true
		else
			@success = false
		end
	end

	#取消订阅 
	def cancel_subscribe
		retval = @client.cancel_subscribe(params[:key])
		Rails.logger.info('---------------------------------')
		Rails.logger.info(retval)
		Rails.logger.info('---------------------------------')
	end

	def show		
	  # @survey = @client.find(params[:id])
	end	

	# Show survey result
	def result
		@survey = @client.show(params[:id])
		render_404 and return if !@survey.success
		@survey = @survey.value

		# get survey questions
		@survey_questions = { :pages => [] }
		page_client = Quill::PageClient.new(session_info, @survey['_id'])
		(@survey['pages'] || []).each_with_index do |page, i|
			result = page_client.get_page_questions(i)
			if result.success
				@survey_questions[:pages] << result.value
			end
		end

		# start to analyze and get job id
		@job_id = Quill::ResultClient.new(session_info).analysis(@survey['_id'], -1, false)
    @job_id.success ? @job_id = @job_id.value : @job_id = nil

		render :layout => 'app'
	end

	private 
	def get_client
	  @client   = Sample::SurveyClient.new(session_info)
	  @answer   = Sample::AnswerClient.new(session_info)
	end

	def resolve_layout
  		case action_name
  		when "active_rss_able"
  			"sample_account"
  		when "cancel_subscribe"
  			"sample_account"
  		else
  		  "sample"
  		end
  	end

	# def make_subscribe
	#   if params[:subscribe_channel].present?
	  	
	#   end
	# end

	# PAGE
	# def show
	# 	load_survey_filler(false)
	# 	render :layout => 'filler'
	# end

	# # PAGE
	# def intro
	# 	@survey = nil
	# 	result = Quill::SurveyClient.new(session_info).get_survey(params[:id])
	# 	if !result.success
	# 		redirect_to surveys_path and return
	# 	else
	# 		@survey = result.value
	# 	end

	# 	return if @survey.nil?

	# 	@status = nil
	# 	if user_signed_in
	# 		# if signed in, get the real answer_id for current user
	# 		result = Quill::AnswerClient.new(session_info).get_my_answer(params[:id], false)
	# 		@status = result.value['status']
	# 	end

	# end
end