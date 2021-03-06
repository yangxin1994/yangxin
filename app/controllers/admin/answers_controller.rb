# encoding: utf-8
# already tidied up
class Admin::AnswersController < Admin::AdminController

  layout "layouts/admin-todc"

  before_filter :require_sign_in, :only => [:index, :create, :update, :destroy]

  def index
    @surveys = auto_paginate(Survey.search(params)) do |paginated_surveys|
      paginated_surveys.map do |s|
        s.write_attribute(:email, s.user.try(:email) || s.user.try(:mobile))
        s.write_attribute(:not_review_answer_num, s.answers.not_preview.unreviewed.length)
        s
      end
    end
  end

  def atachement  
    m = Material.find_by_id(params[:aid])
    if m.present?
      send_file "#{Rails.root.to_s}/public/" + m.value
    end
  end

  def show
    if current_user.is_admin?
      survey = Survey.find(params[:id])
    else
      survey = current_user.answer_auditor_allocated_surveys.find(params[:id])
    end

    @answers = auto_paginate survey.answers.search(params) do |paginated_answers|
      paginated_answers.map do |a|
        if a.user.present?
          a.write_attribute(:user_email_mobile, [a.user.email, a.user.mobile, "游客"].select { |e| e.present? }.first)
          a.write_attribute(:user_id, a.user.id)
        end
        a
      end
    end
  end

  def to_csv
    survey = Survey.find(params[:id])
    answers = survey.answers.search(params)
    if params[:suspected].to_s == "true"
      answers = answers.select { |e| e.suspected == true }
    elsif params[:suspected].to_s == "false"
      answers = answers.select { |e| e.suspected == false }
    end
    csv_string = survey.admin_to_csv(answers || [])
    csv_string ||= ""
    csv_string_gbk = ""
    csv_string.each_char do |csv_str|
      begin
        csv_string_gbk << csv_str.encode("GBK")
      rescue
        csv_string_gbk << ' '
      end
    end
    send_data(csv_string_gbk,
      :filename => "答案数据-#{Time.now.strftime("%M-%d_%T")}.csv", 
      :type => 'text/csv')    
  end

  def review
    @questions = Answer.find(params[:id]).present_auditor
    @survey = @questions.survey
  end

  def set_location
    render_json Answer.find(params[:id]) do |answer|
      answer.latitude = params[:lat]
      answer.longitude = params[:lng]
      answer.save
    end
  end

  def update
    render_json Answer.find(params[:id]) do |answer|
      answer.review(params[:review_result].to_s == "true", current_user, params[:message_content])
    end 
  end

  def reject
    render_json Answer.find(params[:id]) do |answer|
      answer.admin_reject(current_user)
    end
  end

  def batch_reject
    survey = Survey.find(params[:id])

    result = survey.batch_reject(params, current_user)

    send_data(result, 
      :filename => "批量拒绝处理结果-#{Time.now.strftime("%M-%d_%T")}.csv",
      :type => "text/csv")
  end

  def batch_pass
    survey = Survey.find(params[:id])

    result = survey.batch_pass(params, current_user)

    send_data(result, 
      :filename => "批量通过处理结果-#{Time.now.strftime("%M-%d_%T")}.csv",
      :type => "text/csv")
  end
end
