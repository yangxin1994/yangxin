class Filler::FillerController < ApplicationController

  before_filter :force_tablet_html, :check_mobile_param
  has_mobile_fu

  layout 'filler'

  # Continue rendering HTML for tablet
  def force_tablet_html
    session[:tablet_view] = false
  end
  def check_mobile_param
    force_mobile_format if params[:m].to_b
  end    

  def ensure_preview(is_preview)
    @is_preview = is_preview
  end

  def ensure_survey(survey_id)
    @survey = Survey.find(survey_id)
    if !@survey.nil? and @survey.id.to_s == '53e1da56eb0e5b56f50000fa'
      @survey[:lang] = 'en'
    end
    @survey
  end

  def ensure_reward(reward_scheme_id, rewards)
    @reward_scheme_id = reward_scheme_id
    @reward_scheme_type = 0
    return if rewards.blank?
    r = rewards[0]
    case r['type']
    when RewardScheme::MOBILE, RewardScheme::ALIPAY, RewardScheme::JIFENBAO
      if r['amount'] > 0
        @reward_scheme_type = 1
        @reward_money = r["type"] == RewardScheme::JIFENBAO ? r['amount'].to_f / 100 : r['amount']
      end
    when RewardScheme::POINT
      if r['amount'] > 0
        @reward_scheme_type = 2
        @reward_point = r['amount']
        #@hot_gift = Gift.on_shelf.real.desc(:exchange_count).first
        @hot_gift = Gift.on_shelf.real.desc(:exchange_count).limit(3)
      end
    when RewardScheme::LOTTERY
      if r['prizes'].length > 0
        @reward_scheme_type = 3 
        @prizes = r['prizes'].map do |p|
          prize = Prize.find(p['id'])
          {
            title: prize.title,
            amount: p['amount'],
            photo_url: prize.photo.picture_url
          }
        end || []
        @lottery_started = !r['win'].nil?
      end
    end
  end

  def ensure_spread(survey, reward_scheme_id)   
    if reward_scheme_id.present?
      @spread_url = "#{Rails.application.config.quillme_host}#{show_s_path(reward_scheme_id)}" unless user_signed_in
      @spread_url = "#{Rails.application.config.quillme_host}#{show_s_path(reward_scheme_id)}?i=#{current_user._id}" if user_signed_in 
      @spread_url = "#{Rails.application.config.quillme_host}/#{MongoidShortener.generate(@spread_url)}"
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
    if @survey.is_a? SurveyTask
      redirect_to @survey.get_encoded_url(current_user)
      return
    end
    # 4. Check whether an answer for this survey is already exist.
    #    If the user is signed in, ask his answer from Quill.
    #    If the user is not signed in, check the cookie
    #    If answer exists, get percentage
    if user_signed_in
      answer = Answer.find_by_survey_id_sample_id_is_preview(survey_id, current_user._id.to_s, is_preview)
    else
      answer = Answer.find_by_id(cookies[cookie_key(survey_id, is_preview)])
    end
    if answer.is_a? AnswerTask
      redirect_to "/"
      return
    end
    @percentage = -1
    if answer.present?
      if answer.user.present? && answer.user != current_user
        cookies.delete(cookie_key(survey_id, is_preview), :domain => :all)
        answer = nil
      else
        answer.update_status
        redirect_to show_a_path(answer.id.to_s) and return if !answer.is_edit
        @percentage = answer.answer_percentage
      end
    else
    	cookies.delete(cookie_key(survey_id, is_preview), :domain => :all)
    end

    # 5. get real reward
    #    If answer exists, reward is in answer; 
    #    if answer does not exist, reward is in reward scheme
    ensure_reward(reward_scheme_id, answer.nil? ? reward_scheme.rewards : answer.rewards)

    # 6. Check whether survey is closed or not
    @survey_closed = !@is_preview && @survey.status != Survey::PUBLISHED
    if params[:ati].present?
      # checkout whether agent task is already closed
      agent_task = AgentTask.find(params[:ati])
      if agent_task.blank? || agent_task.status != AgentTask::OPEN
        @survey_closed = true
      end
    end
    
    # 10. get request referer and channel
    @channel = params[:c].to_i
    begin
      @referer_host = URI.parse(request.referer).host.downcase if request.referer.present?
    rescue => ex
      logger.debug ex
    end

    # 11. ensure spread url
    ensure_spread(@survey, reward_scheme_id)

    # 12. check ip restrict
    @forbidden_ip = !is_preview && !answer.present? && @survey.max_num_per_ip_reached?(request.remote_ip)
  end
end
