class Filler::FillerController < ApplicationController
	# has_mobile_fu
 #  before_filter :set_mobile_format, :check_mobile_param

 #  # Continue rendering HTML for the iPad (no mobile views yet)
 #  def set_mobile_format
 #    is_device?("ipad") ? request.format = :html : super
 #  end
 #  def check_mobile_param
 #  	force_mobile_format if params[:m].to_b
 #  end

	layout 'filler'

	def ensure_preview(is_preview)
		@is_preview = is_preview
	end

	def ensure_survey(survey_id)
		result = Sample::SurveyClient.new(session_info).show(survey_id)
		if !result.success || result.value['status'] == 4
			# render 500 exception or 
			# if survey not exist or survey is deleted, return error
			result.unknown_error? ? render_500 : render_404
		end
		@survey = result.value
	end

	def ensure_reward(reward_scheme_id, rewards)
		@reward_scheme_id = reward_scheme_id
		@reward_scheme_type = 0
		if !rewards.nil? && rewards.length > 0
			rewards.each do |r|
				case r['type']
				when 1, 2
					if r['amount'] > 0
						@reward_scheme_type = 1
						@reward_money = r['amount']
						break
					end
				when 4
					if r['amount'] > 0
						@reward_scheme_type = 2
						@reward_point = r['amount']
						# get hottest gift
						@hot_gift = nil
						gifts = Sample::GiftClient.new(session_info).get_hoest(1, 1, 'exchange_count')
						if gifts.success && gifts.value['data'] && gifts.value['data'].length > 0
							@hot_gift = gifts.value['data'][0]
						end
						break
					end
				when 8
					if r['prizes'].length > 0
						@reward_scheme_type = 3 
						p_client = Sample::PrizeClient.new(session_info)
						@prizes = r['prizes'].map do |p|
							prize = p_client.show_one(p['id'])
							{
								title: prize.value['title'],
								amount: p['amount'],
								photo_url: prize.value['photo_url']
							}
						end || []
						break
					end
				when 16
					if r['amount'] > 0
						@reward_scheme_type = 1
						@reward_money = r['amount'].to_f / 100
						break
					end
				end
			end
		end
	end

	def ensure_spread(survey, reward_scheme_id)
		# get spread url
		@spread_url = nil
		if user_signed_in && survey['spread_point'] > 0
			@spread_url = "#{Rails.application.config.quillme_host}#{show_s_path(reward_scheme_id)}?i=#{user_id}"
			result = ::ShortUrlClient.new(session_info).create(@spread_url)
			if result.success && !result.value.blank?
				@spread_url = "#{Rails.application.config.quillme_host}/#{result.value}"
			end
		end
	end

	def cookie_key(survey_id, is_preview)
		return "#{survey_id}_#{is_preview ? 1 : 0}"
	end

	# =============================
	# Load survey filler
	# =============================
	def load_survey(reward_scheme_id, is_preview = false)
		# ensure preview
		ensure_preview(is_preview)

		# 1. ensure reward_scheme exist
		# 2. get survey_id from rewarc_scheme
		# 3. ensure survey exist and not deleted
		render_404 if reward_scheme_id.nil?
		reward_scheme = Sample::RewardSchemeClient.new(session_info, reward_scheme_id).show()
		render_404 if !reward_scheme.success
		survey_id = reward_scheme.value['survey_id']
		ensure_survey(survey_id)

		# 4. Check whether an answer for this survey is already exist.
		#    If the user is signed in, ask his answer from Quill.
		#    If the user is not signed in, check the cookie
		#    If answer exists, get percentage
		answer_id = nil
		if user_signed_in
			result = Sample::AnswerClient.new(session_info).get_answer_id_by_auth_key(survey_id, is_preview)
			if result.success
				answer_id = result.value
			elsif result.value['error_code'] == 'error_7'	
				# if the current session in QuillWeb is valid but authkey in Quill is invalid, logout
				_sign_out request.url and return
			end
		else
			answer_id = cookies[cookie_key(survey_id, is_preview)]
		end
		@percentage = 0
		if !answer_id.blank?
			# if answer exist, load next page questions
			data = Sample::AnswerClient.new(session_info, answer_id).load_questions
			if data.success
				if data.value['answer_status'] == 1 && data.value['questions'].length > 0
					# if data.value['questions'].length == 0
					# survey has no question or the user has finished all question but not submitted the survey yet
					@percentage = data.value['answer_index'].to_f / data.value['question_number'].to_f
				else
					redirect_to show_a_path(answer_id) and return
				end
			else
				# if failed to load next page. and the user is not signin, clear this illegal answer id in cookie
				answer_id = nil
				cookies.delete(cookie_key(survey_id, is_preview), :domain => :all)
			end
		end

		# 5. get real reward
		#    If answer exists, reward is in answer; 
		#    if answer does not exist, reward is in reward scheme
		answer = nil
		if !answer_id.blank?
			answer = Sample::AnswerClient.new(session_info, answer_id).show
			answer.success ? answer = answer.value : answer = nil;
		end
		ensure_reward(reward_scheme_id, answer.nil? ? reward_scheme.value['rewards'] : answer['rewards'])

		# 6. Check whether survey is closed or not
		@survey_closed = false
		if !@is_preview && @survey['status'] != 2
			# if is filler and survey's status is not published
			@survey_closed = true
		end

		# 7. Estimate survey filler time
		result = Sample::SurveyClient.new(session_info).estimate_answer_time(survey_id)
		@left_time = (result.success ? result.value : -1)

		# 8. If is hot survey and user is signed in, check whether is new user or not
		@answer_count_empty = true
		if @survey['quillme_hot'] && user_signed_in
			result = Sample::UserClient.new(session_info).get_basic_info
			@answer_count_empty = (result.success && result.value['answer_number'] == 0)
		end

		# 10. get request referer and channel
		@channel = params[:c].to_i
		begin
			if !request.referer.blank?
				ref_uri = URI.parse(request.referer)
				# if !ref_uri.host.downcase.end_with?(request.domain.downcase)
					@referer_host = ref_uri.host.downcase
				# end
			end
		rescue => ex
			logger.debug ex
		end

		# 11. ensure spread url
		ensure_spread(@survey, reward_scheme_id)
	end

end