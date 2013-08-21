class Admin::AnswersController < Admin::AdminController

  layout "layouts/admin-todc"

  before_filter :require_sign_in, :only => [:index, :create, :update, :destroy]

  def index
    @surveys = auto_paginate(Survey)
  end

  def show
    if current_user.is_admin?
      survey = Survey.find(params[:id])
    else
      survey = current_user.answer_auditor_allocated_surveys.find(params[:id])
    end

    @answers = auto_paginate survey.answers.find_by_status(params[:status])
  end

  def review
    @questions = Answer.find(params[:id]).present_auditor
  end

  def update
    render_json Answer.find(params[:id]) do |answer|
      answer.review(params[:review_result].to_s == "true", current_user, params[:message_content])
    end 
  end

end