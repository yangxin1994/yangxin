class Sample::SurveysController < Sample::SampleController

	layout :resolve_layout

	def initialize
		super('survey')
	end

	# PAGE
	def index
		@surveys = Survey.get_recommends(params[:status],
			params[:reward_type],
			params[:answer_status],
			current_user,
			nil)
		@surveys = @surveys.map { |e| e.excute_sample_data(current_user) }
		@surveys = auto_paginate @surveys
		date = Date.today
		today_start = Time.local(date.year, date.month, date.day,0,0,0)
		today_end   = Time.local(date.year, date.month, date.day+1,0,0,0)
		@answer_count = Answer.where(:created_at.gte => today_start,:created_at.lt => today_end).count
		date = Date.today
		today_start = Time.local(date.year, date.month, date.day,0,0,0)
		today_end   = Time.local(date.year, date.month, date.day+1,0,0,0)
		@spread_count = Answer.where(:created_at.gte => today_start,:created_at.lt => today_end,:introducer_id.ne => nil).count
		@disciplinal = PunishLog.desc(:created_at).limit(3).map do |log|
			log['avatar'] = log.user.avatar.present? ? log.user.avatar.picture_url : User::DEFAULT_IMG
			log['username'] = log.user.try(:nickname)
			log
		end
		@reward_count = Survey.get_reward_type_count(params[:status])
		@fresh_news = Log.get_new_logs(3, 1).each do |log|
			log['avatar'] = log.user.avatar.present? ? log.user.avatar.picture_url : User::DEFAULT_IMG
			log['username'] = log.user.try(:nickname)
			log      
		end
	end

	#重新生成订阅 短信激活码  或者邮件
	def make_rss_activate
		retval = User.create_rss_user(params[:rss_channel], "#{request.protocol}#{request.host_with_port}/surveys/active_rss_able")
		render :json => retval and return
	end


	def make_rss_mobile_activate
		user   = User.find_by_mobile(params[:rss_channel])
		return ErrorEnum::USER_NOT_EXIST  if user.nil?
		retval = user.make_mobile_rss_activate(params[:code])
		render_json_auto retval and return
	end

	#订阅邮件 callback链接
	def active_rss_able
		begin
			activate_info_json = Encryption.decrypt_activate_key(params[:key])
			activate_info = JSON.parse(activate_info_json)
			retval = User.activate_rss_subscribe(activate_info)
			@success = false and return if retval != true
			@success = true
			@email = activate_info["email"]
		rescue
			@success = false and return
		end
	end

	#取消订阅 
	def cancel_subscribe
		begin
			activate_info_json = Encryption.decrypt_activate_key(params[:key])
			activate_info = JSON.parse(activate_info_json)
			retval = User.cancel_subscribe(activate_info)
		rescue
			render_500
		end
	end

	def show		
	end	

	# Show survey result
	def result
		@survey = Survey.find_by_id(params[:id])
		render_404 and return if @survey.nil?

		# get survey questions
		@survey_questions = { :pages => [] }
		(@survey.pages || []).each_with_index do |page, i|
			@survey_questions[:pages] << @survey.show_page(i)
		end

		@job_id = @survey.analysis(-1, params[:false])
		@job_id = nil if @job_id.start_with?("error_")

		render :layout => 'app'
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
end