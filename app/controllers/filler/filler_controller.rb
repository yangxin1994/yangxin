# finish migrating
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
		@survey = Survey.find_by_id(survey_id)
		if @survey.nil?
			render_404
		end
	end

	def ensure_reward(reward_scheme_id, rewards)
		logger.debug '=============='
		logger.debug rewards.inspect
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
						@hot_gift = Gift.on_shelf.real.desc(:exchange_count).first.info
						break
					end
				when 8
					if r['prizes'].length > 0
						@reward_scheme_type = 3 
						@prizes = r['prizes'].map do |p|
							prize = Prize.find_by_id(p['id'])
							{
								title: prize.title,
								amount: p['amount'],
								photo_url: prize.photo.picture_url
							}
						end || []
						# win: nil, false, true
						@lottery_started = !r['win'].nil?
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
			@spread_url = "#{Rails.application.config.quillme_host}#{show_s_path(reward_scheme_id)}?i=#{current_user._id}"
			result = MongoidShortener.generate(@spread_url)
			@spread_url = "#{Rails.application.config.quillme_host}/#{result}"
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
		reward_scheme = RewardScheme.find_by_id(reward_scheme_id)
		render_404 if reward_scheme.nil?
		survey_id = reward_scheme.survey_id
		ensure_survey(survey_id)

		# 4. Check whether an answer for this survey is already exist.
		#    If the user is signed in, ask his answer from Quill.
		#    If the user is not signed in, check the cookie
		#    If answer exists, get percentage
		answer_id = nil
		if user_signed_in
			answer = Answer.find_by_survey_id_sample_id_is_preview(survey_id, current_user._id.to_s, is_preview)
			answer_id = answer._id.to_s if answer.present?
		else
			answer_id = cookies[cookie_key(survey_id, is_preview)]
		end
		@percentage = 0
		answer = answer_id.present? ? Answer.find_by_id(answer_id) : nil
		if answer.present?
			# if answer exist, load next page questions
			if answer.user.present? && answer.user != current_user
				answer_id = nil
				cookies.delete(cookie_key(survey_id, is_preview), :domain => :all)
			end
			answer.update_status
			questions = answer.load_question(nil, true) if answer.is_edit

			if answer.is_edit
				answer_index = answer.index_of(questions)
				question_number = answer.survey.all_questions_id(false).length + answer.random_quality_control_answer_content.length
				@percentage = answer_index.to_f / question_number.to_f
			else
				redirect_to show_a_path(answer_id) and return
			end

		end

		# 5. get real reward
		#    If answer exists, reward is in answer; 
		#    if answer does not exist, reward is in reward scheme
		ensure_reward(reward_scheme_id, answer.nil? ? reward_scheme.rewards : answer.rewards)

		# 6. Check whether survey is closed or not
		@survey_closed = false
		if !@is_preview && @survey.status != Survey::PUBLISHED
			# if is filler and survey's status is not published
			@survey_closed = true
		end

		# 7. Estimate survey filler time
		@left_time = @survey.estimate_answer_time

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

		# 12. check ip restrict
		@forbidden_ip = !is_preview && !answer.present? && @survey.max_num_per_ip_reached?(request.remote_ip)
	end
end