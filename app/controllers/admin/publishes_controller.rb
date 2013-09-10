class Admin::PublishesController < Admin::AdminController

	layout 'admin_new'

	before_filter :get_client, :except => [:create_simple_interviewer_task, :update_simple_interviewer_task]

	def get_client
		@client = BaseClient.new(session_info, "/admin/surveys")
	end

	#********************

	#********************

	def index
		params_hash = {:page => page, :per_page => per_page}
		params_hash.merge!({:publish_status => params[:publish_status].to_i}) if params[:publish_status]
		params_hash.merge!({:show_in_community => params[:show_in_community].to_s == "true"}) if params[:show_in_community]
		params_hash.merge!({:title => params[:title]}) if params[:title]
		params_hash.merge!({:email => params[:email]}) if params[:email]
		@surveys = @client._get(params_hash, '')

		respond_to do |format|
			format.html
			format.json { render json: @surveys}
		end
	end

	def show
		@survey = @client._get({}, "/#{params[:id]}")
		logger.debug @survey.inspect

		@sent_email_number = BaseClient.new(session_info, "/admin/surveys/#{params[:id]}/get_sent_email_number")._get({})
		if @sent_email_number.success
			@sent_email_number = @sent_email_number.value
		else
			@sent_email_number = -1
		end

		@tasks = BaseClient.new(session_info, "/admin/interviewer_tasks")._get({:survey_id => params[:id]})
		respond_to do |format|
			format.html
			format.json { render json: @survey}
		end

	end

	def destroy
		render :json => @client._delete({}, "/#{params[:id]}")
	end

	# **************************

	def allocate
		render :json => @client._put({
				:system_user_type => params[:system_user_type],
				:user_id => params[:user_id],
				:allocate => params[:allocate]
			}, "/#{params[:id]}/allocate")
	end

	def add_reward
		params_hash = {:reward => params[:reward].to_i}
		params_hash.merge!({:point => params[:point].to_i}) if params[:point] && params[:reward].to_i ==2
		params_hash.merge!({:lottery_id => params[:lottery_id]}) if params[:lottery_id].to_s.strip!="" && params[:reward].to_i ==1
		render :json => @client._put(params_hash, "/#{params[:id]}/add_reward")
	end

	def set_community
		render :json => @client._put({show_in_community: true}, "/#{params[:id]}/set_community")
	end

	def cancel_community
		render :json => @client._put({show_in_community: false}, "/#{params[:id]}/set_community")
	end

	def set_answer_need_review
		render :json => @client._put({answer_need_review: params['answer_need_review']}, "/#{params[:id]}/set_answer_need_review")
	end

	def set_spread
		render :json => @client._put({
				:spread_point => params[:spread_point].to_i,
				:spreadable => params[:spreadable]
			}, "/#{params[:id]}/set_spread")
	end

	def set_promotable
		render :json => @client._put({
			promotable: params['promotable'],
			promote_email_number: params['promote_email_number'].to_i
			}, "/#{params[:id]}/set_promotable")
	end

end
