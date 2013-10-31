class Sample::SurveysController < Sample::SampleController

  layout :resolve_layout

  # PAGE
  def index
    
    surveys = Survey.get_recommends(
      sample:current_user,
      status:params[:status],
      reward_type:params[:reward_type],
      answer_status:params[:answer_status])

    surveys = surveys.map { |e| e.excute_sample_data(current_user) }
    surveys = auto_paginate surveys

    date = Date.today
    today_start = Time.local(date.year, date.month, date.day,0,0,0)
    today_end = Time.at(today_start.to_i + 1.days.to_i)

    answer = Answer.where(:created_at.gte => today_start,:created_at.lt => today_end)

    @data = {
      surveys:surveys,
      answer_count:answer.count,
      spread_count:answer.where(:introducer_id.ne => nil).count,
      disciplinal:PunishLog.desc(:created_at).limit(3),
      reward_count:Survey.get_reward_type_count(params[:status])
    }

    fresh_when(:etag => @data)
    
  end

  #重新生成订阅 短信激活码  或者邮件
  def generate_rss_activate_code
    retval = User.create_rss_user(
      params[:rss_channel],
      {
        protocol_hostname: "#{request.protocol}#{request.host_with_port}",
        path: "/surveys/email_rss_activate"
      })
    
    render :json => retval and return
  end


  def mobile_rss_activate
    user   = User.find_by_mobile(params[:rss_channel])
    return ErrorEnum::USER_NOT_EXIST  if user.nil?
    retval = user.make_mobile_rss_activate(params[:code])
    render_json_auto retval and return
  end

  #订阅邮件 callback链接
  def email_rss_activate
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

  # Show survey result
  def result
    @survey = Survey.find_by(id: params[:id])
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
      when "email_rss_activate"
        "sample_account"
      when "cancel_subscribe"
        "sample_account"
      else
        "sample"
      end
    end
end
