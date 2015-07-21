# encoding: utf-8
require 'array'
class Filler::AnswersController < Filler::FillerController
  def create
    # hack: if the cookie has already has an answer_id and is not signed in, return the answer_id
    # Used to avoid creating multiple answers when user click the back key in the keyboard when answeing survey
    if !user_signed_in
      params[:is_preview] = false if params[:is_preview] == 'false'
      answer_id = cookies[cookie_key(params[:survey_id], params[:is_preview])]
      render_json_auto answer_id and return if answer_id.present?
    end

    if params[:agent_task_id] && params[:agent_user_id].present?
      agent_task = AgentTask.find(params[:agent_task_id])
      answer = agent_task.answers.where(agent_user_id: params[:agent_user_id]).first
      render_json_auto answer.id.to_s and return if answer.present?
    end

    survey = Survey.normal.find_by_id(params[:survey_id])
    answer = Answer.find_by_survey_id_sample_id_is_preview(params[:survey_id], current_user.try(:_id), params[:is_preview] || false)
    answer ||= Answer.find_by_survey_id_carnival_user_id_is_preview(params[:survey_id], current_carnival_user.try(:_id), params[:is_preview] || false)
    render_json_s(answer._id.to_s) and return if !answer.nil?
    render_json_e ErrorEnum::MAX_NUM_PER_IP_REACHED and return if !params[:is_preview] && survey.max_num_per_ip_reached?(request.remote_ip)
    retval = survey.check_password(params[:username], params[:password], params[:is_preview] || false)
    render_json_e ErrorEnum::WRONG_SURVEY_PASSWORD and return if retval != true
    answer = { is_preview: params[:is_preview] || false,
      channel: params[:channel],
      referrer: params[:referrer],
      remote_ip: request.remote_ip,
      ip_address: request.remote_ip,
      username: params[:username],
      password: params[:password],
      http_user_agent: request.env['HTTP_USER_AGENT'] }
    answer = Answer.create_answer(params[:survey_id],
      params[:reward_scheme_id],
      params[:introducer_id],
      params[:agent_task_id],
      params[:agent_user_id],
      params[:task_id],
      answer )
    if Carnival::ALL_SURVEY.include?(params[:survey_id])
      current_carnival_user.answers << answer if current_carnival_user.present?
      current_carnival_user.fill_answer(answer) if current_carnival_user.present?
    else
      current_user.answers << answer if current_user.present?
    end
    answer.check_channel_ip_address_quota
    if !user_signed_in
      # If a new answer for the survey is created, and the user is not signed in
      # store the answer id in the cookie
      cookies[cookie_key(params[:survey_id], params[:is_preview])] = { 
        :value => answer._id.to_s, 
        :expires => Rails.application.config.answer_id_time_out_in_hours.hours.from_now ,
        :domain => :all
      }
    end
    render_json_auto answer.id.to_s
  end

  # def submit_mobile
  #   @answer = Answer.find_by_id(params[:id])
  #   render_404 if @answer.nil?
  #   survey = @answer.survey
  #   agent_answers = survey.answers.select { |e| e.agent_task.present? }
  #   existing_mobiles = agent_answers.map { |e| e.mobile }
  #   if existing_mobiles.include?(params[:mobile])
  #     render_json_auto ErrorEnum::MOBILE_EXIST and return
  #   end
  #   @answer.mobile = params[:mobile]
  #   @answer.save
  #   render_json_auto @answer.id.to_s and return
  # end

  def submit_mobile
    @answer = Answer.find_by_id(params[:id])
    render_404 if @answer.nil?
    survey = @answer.survey
    # agent_answers = survey.answers.select { |e| e.agent_task.present? }
    # exist_answer = agent_answers.select{|e| e.mobile == params[:mobile]}
    exist_answer = survey.answers.where(:agent_task_id.ne => nil, :mobile => params[:mobile])
    if exist_answer.length > 0
      if exist_answer.first.status != Answer::EDIT
        render_json_auto ErrorEnum::MOBILE_EXIST and return
      else
        @answer = exist_answer.first
        render_json_auto @answer.id.to_s and return
      end
    else
      @answer.mobile = params[:mobile]
      @answer.save
      render_json_auto @answer.id.to_s and return      
    end
  end





  def ask_for_mobile
    @answer = Answer.find_by_id(params[:id])
    ensure_survey(@answer.survey_id)
  end

  def show
    # get answer
    @answer = Answer.find_by_id(params[:id])
    render_404 if @answer.nil?
    redirect_to "/" and return if @answer.is_a? AnswerTask

    # if the sample is from an agent, check whether the mobile has been submitted
    if @answer.agent_task.present? && @answer.mobile.blank?
      redirect_to ask_for_mobile_answer_path(:id => params[:id]) and return
    end

    # load data
    redirect_to sign_in_account_path({ref: request.url}) and return if @answer.user.present? && @answer.user != current_user

    
    if @answer.survey.wechart_promotable
      #调用微信的分享接口需要的配置
      generate_wechart_sign
      
      #领取红包用
      cookies[:awd] =  {
        :value => params[:id],
        :expires => Rails.application.config.permanent_signed_in_months.months.from_now,
        :domain => :all
      }
      # 领取红包用
      if cookies[:od].blank?
        code = params[:code]
        if code.nil?
          redirect_to Wechart.snsapi_base_redirect(request.url,request.url)
        else
          begin
            openid = Wechart.get_open_id(code)
            Rails.logger.info '-------------------------'
            Rails.logger.info openid
            Rails.logger.info '-------------------------'
            cookies[:od] = {
              :value => openid,
              :expires => Rails.application.config.permanent_signed_in_months.months.from_now,
              :domain => :all
            }
            @answer.update_attributes(open_id:openid) if @answer.open_id.blank?
          rescue Exception => e
              render_500
          end
        end        
      end 
    end

    @answer.update_status # check whether it is time out
    if @answer.is_edit
      questions = @answer.load_question(nil, true)
      question_ids = questions.map { |e| e._id.to_s }
      if @answer.is_finish
        retval = {"answer_status" => @answer.status,
          "answer_reject_type" => @answer.reject_type,
          "answer_audit_message" => @answer.audit_message,
          "order_id" => @answer.order.try(:id),
          "order_code" => @answer.order.try(:code),
          "order_amount" => @answer.order.try(:amount),
          "order_status" => @answer.order.try(:status)}
      else
        answers = @answer.answer_content.merge(@answer.random_quality_control_answer_content)
        answers = answers.select { |k, v| question_ids.include?(k) }
        retval = {"answer_status" => @answer.status,
          "questions" => questions,
          "answers" => answers,
          "question_number" => @answer.survey.all_questions_id(false).length + @answer.random_quality_control_answer_content.length,
          "answer_index" => @answer.index_of(questions),
          "answer_index_all" => @answer.index_of(questions, true),
          "estimate_answer_time" => questions.estimate_answer_time,
          "repeat_time" => @answer.repeat_time,
          "order_id" => @answer.order.try(:_id),
          "order_code" => @answer.order.try(:code),
          "order_amount" => @answer.order.try(:amount),
          "order_status" => @answer.order.try(:status)}
      end
    else
      retval = {"answer_status" => @answer.status,
        "answer_reject_type" => @answer.reject_type,
        "answer_audit_message" => @answer.audit_message,
        "order_id" => @answer.order.try(:_id),
        "order_code" => @answer.order.try(:code),
        "order_amount" => @answer.order.try(:amount),
        "order_status" => @answer.order.try(:status)}
    end
    @data = {:success => true, :value => retval}

    ensure_preview(@answer.is_preview)

    ensure_survey(@answer.survey_id)

    ensure_reward(@answer.reward_scheme_id.to_s, @answer.rewards)

    ensure_spread(@survey, @answer.reward_scheme_id)

    if @answer.carnival_user_id.present?
      cookies[:carnival_user_id] = {
        :value => @answer.carnival_user_id,
        :expires => 12.months.from_now,
        :domain => :all
      }
    end

    if @survey.title.match(/网络视频使用行为调查/)
      @redirect_link = generate_iqiyi_link
    end

    @binded = user_signed_in ? (current_user.email_activation || current_user.mobile_activation) : false

  end


  def destroy_preview
    @answer = Answer.preview.find(params[:id])
    # delete cookie
  	cookies.delete(cookie_key(@answer.survey_id.to_s, @answer.is_preview), :domain => :all)
    @answer.survey.answers.delete(@answer)
    render_json_auto @answer.destroy and return 
  end

  def replay
    @answer = Answer.find(params[:id])
    cookies.delete(cookie_key(@answer.survey_id.to_s, @answer.is_preview), :domain => :all)
    survey = @answer.survey
    survey.recover_password(@answer)
    survey.answers.delete(@answer)
    survey.decrease_quota(@answer)
    render_json_auto @answer.destroy and return 
  end

  def clear
    @answer = Answer.find(params[:id])
    @answer.clear
    if @answer.carnival_user.present?
      @answer.carnival_user.fill_answer(@answer)
    end
    render_json_auto true and return
  end


  def update_for_mobile
    update()
  end

  # AJAX
  def update
    @answer = Answer.find(params[:id])
    # 0. check the answer's status
    render_json_e(ErrorEnum::WRONG_ANSWER_STATUS) and return if !@answer.is_edit
    # 1. update the answer content
    @answer.update_answer(params[:answer_content] || {})
	  logger.info @answer.answer_content.inspect
    # 2. check quality control
    passed = @answer.check_quality_control(params[:answer_content] || {})
	  logger.info @answer.answer_content.inspect
    # 3. check screen questions
    passed &&= @answer.check_screen(params[:answer_content] || {})
	  logger.info @answer.answer_content.inspect
    # 4. check quota questions (skip for previewing)
    passed &&= @answer.check_question_quota(params[:answer_content] || {}) if !@answer.is_preview
	  logger.info @answer.answer_content.inspect
    # 5. update the logic control result
    @answer.update_logic_control_result(params[:answer_content] || {}) if passed
	  logger.info @answer.answer_content.inspect
    # 6. automatically finish the answers that do not allow pageup
    @answer.finish(true) if passed
	  logger.info @answer.answer_content.inspect
    render_json_s and return
  end

  # AJAX
  def load_questions
    @answer = Answer.find_by_id(params[:id])
    render_json_e ErrorEnum::ANSWER_NOT_EXIST and return if @answer.nil?
    render_json_e ErrorEnum::REQUIRE_LOGIN and return if @answer.user.present? && @answer.user != current_user
    @answer.update_status # check whether it is time out
    if @answer.is_edit
      questions = @answer.load_question(params[:start_from_question], params[:load_next_page].to_s == "true")
      question_ids = questions.map { |e| e._id.to_s }
      if @answer.is_finish
        retval = {"answer_status" => @answer.status,
          "answer_reject_type" => @answer.reject_type,
          "answer_audit_message" => @answer.audit_message,
          "order_id" => @answer.order.try(:id),
          "order_status" => @answer.order.try(:status)}
        render_json_auto(retval) and return
      else
        answers = @answer.answer_content.merge(@answer.random_quality_control_answer_content)
        answers = answers.select { |k, v| question_ids.include?(k) }
        retval = {"answer_status" => @answer.status,
          "questions" => questions,
          "answers" => answers,
          "question_number" => @answer.survey.all_questions_id(false).length + @answer.random_quality_control_answer_content.length,
          "answer_index" => @answer.index_of(questions),
          "answer_index_all" => @answer.index_of(questions, true),
          "estimate_answer_time" => questions.estimate_answer_time,
          "repeat_time" => @answer.repeat_time,
          "order_id" => @answer.order.try(:_id),
          "order_status" => @answer.order.try(:status)}
        render_json_auto(retval) and return
      end
    else
      retval = {"answer_status" => @answer.status,
        "answer_reject_type" => @answer.reject_type,
        "answer_audit_message" => @answer.audit_message,
        "order_id" => @answer.order.try(:_id),
        "order_status" => @answer.order.try(:status)}
      render_json_auto(retval) and return
    end
  end

  # AJAX
  def finish
    render_json_auto Answer.find(params[:id]).finish and return
  end


  # AJAX
  def select_reward
    render_json_auto Answer.find(params[:id]).select_reward(params[:type], params[:account], current_user)
  end

  def select_reward_for_mobile
    select_reward()
  end

  # AJAX
  def start_bind
    bind_ids = (cookies[Rails.application.config.bind_answer_id_cookie_key] || '').split('_')
    cookies[Rails.application.config.bind_answer_id_cookie_key] = { 
      :value => bind_ids.push(params[:id]).uniq.join('_'), 
      :expires => Rails.application.config.answer_id_time_out_in_hours.hours.from_now ,
      :domain => :all
    }
    render_json_auto
  end


  def generate_iqiyi_link
    ip   = @answer.ip_address
    t    = Time.now.to_i
    str  = "ip=#{ip}t=#{t}gbcnfc0de888db8a"
    sign = Digest::MD5.hexdigest(str)    
    link = @answer.survey.style_setting['redirect_link'].to_s + "?sign=#{sign}&ip=#{ip}&t=#{t}"
  end

  # 生成微信js-sdk签名
  def generate_wechart_sign
      @appid        = Wechart.appid
      @noncestr     = newpass
      @jsapi_ticket = Wechart.jsapi_ticket
      @timestamp    = Time.now.to_i
      @url          = request.url
      string1       = "jsapi_ticket=#{@jsapi_ticket}&noncestr=#{@noncestr}&timestamp=#{@timestamp}&url=#{@url}"
      @signure      =  Digest::SHA1.hexdigest(string1)
  end

  def newpass
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    newpass = ""
    1.upto(16) { |i| newpass << chars[rand(chars.size-1)] }
    return newpass
  end


end
