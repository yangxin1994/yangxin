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

  def review
    @questions = Answer.find(params[:id]).present_auditor
    @survey = @questions.survey
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
end
