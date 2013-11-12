# already tidied up
class Admin::AnswersController < Admin::AdminController

  layout "layouts/admin-todc"

  before_filter :require_sign_in, :only => [:index, :create, :update, :destroy]

  def index
    @surveys = auto_paginate(Survey.search(params)) do |paginated_surveys|
      paginated_surveys.map do |s|
        s.write_attribute(:email, s.user.email || s.user.mobile)
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

    @answers = auto_paginate survey.answers.not_preview.find_by_status(params[:status]) do |paginated_answers|
      paginated_answers.map do |a|
        if a.user.present?
          a.write_attribute(:user_email_mobile, a.user.try(:email) || a.user.try(:mobile))
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

end