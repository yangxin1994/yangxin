class Filler::AnswersController < Filler::FillerController
	
	before_filter :get_ws_client

	def get_ws_client
		@ws_client = Sample::AnswerClient.new(session_info, params[:id])
	end

	# AJAX
	def create
		# hack: if the cookie has already has an answer_id and is not signed in, return the answer_id
		# Used to avoid creating multiple answers when user click the back key in the keyboard when answeing survey
		if !user_signed_in
			answer_id = cookies[cookie_key(params[:survey_id], params[:is_preview])]
			if !answer_id.blank?
				render :json => { success: true, value: answer_id } and return
			end
		end

		result = @ws_client.create(
			params[:survey_id], params[:is_preview], params[:reward_scheme_id], params[:introducer_id], 
			params[:agent_task_id], params[:channel], params[:referer], params[:username], params[:password]
			)
		if result.success && !user_signed_in
			# If a new answer for the survey is created, and the user is not signed in
			# store the answer id in the cookie
			cookies[cookie_key(params[:survey_id], params[:is_preview])] = { 
				:value => result.value, 
				:expires => Rails.application.config.answer_id_time_out_in_hours.hours.from_now ,
				:domain => :all
			}
		end
		render :json => result
	end

	# PAGE
	def show
		# get answer
		answer = @ws_client.show()
		if answer.success
			answer = answer.value
		else
			answer.unknown_error? ? render_500 : render_404
		end

		# load data
		@data = @ws_client.load_questions
		if !@data.success
			@data.unknown_error? ? render_500 : render_404
		end

		# ensure preview
		ensure_preview(answer['is_preview'])

		# ensure survey
		ensure_survey(answer['survey_id'])

		# ensure reward, use the reward info in answer
		ensure_reward(answer['reward_scheme_id'], answer['rewards'])

		# ensure spread url
		ensure_spread(@survey, answer['reward_scheme_id'])

		# load user bind info
		@binded = false
		if user_signed_in
			result = Sample::UserClient.new(session_info).bindings
			logger.debug '============='
			logger.debug result.inspect
			if result.success && result.value
				@binded = (!result.value['email'].nil? && result.value['email'][1]) ||
					(!result.value['mobile'].nil? && result.value['mobile'][1])
			end
		end

	end

	# AJAX
	def destroy_preview
		render :json => @ws_client.destroy_preview
	end
	def clear
		render :json => @ws_client.clear
	end

	# AJAX
	def update
		render :json => @ws_client.submit_answer(params[:answer_content])
	end

	# AJAX
	def load_questions
		render :json => @ws_client.load_questions(params[:start_from_question], params[:load_next_page])
	end

	# AJAX
	def finish
		render :json => @ws_client.finish 
	end

	# AJAX
	def select_reward
		reward_index = -1
		mobile = nil
		alipay_account = nil
		answer = @ws_client.show()
		answer.value['rewards'].each_with_index do |r, i|
			case r['type']
			when 1
				if r['amount'] > 0 && params[:type] == 'chongzhi'
					reward_index = i
					mobile = params[:account]
					break
				end
			when 2
				if r['amount'] > 0 && params[:type] == 'zhifubao'
					reward_index = i
					alipay_account = params[:account]
					break
				end
			when 16
				if r['amount'] > 0 && params[:type] == 'jifenbao'
					reward_index = i
					alipay_account = params[:account]
					break
				end
			when 8
				if r['prizes'].length > 0
					reward_index = i
					break
				end
			end
		end
		render :json => @ws_client.select_reward(reward_index, mobile, alipay_account)
	end

	# AJAX
	def start_bind
		bind_ids = (cookies[Rails.application.config.bind_answer_id_cookie_key] || '').split('_')
		bind_ids << params[:id]
		bind_ids.uniq!
		cookies[Rails.application.config.bind_answer_id_cookie_key] = { 
			:value => bind_ids.join('_'), 
			:expires => Rails.application.config.answer_id_time_out_in_hours.hours.from_now ,
				:domain => :all
		}
		render :json => Common::ResultInfo.ok
	end

end