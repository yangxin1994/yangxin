# finish migrating
require 'error_enum'
class Quill::QuestionairesController < Quill::QuillController

  before_filter :require_sign_in, :only => [:index, :show]
  # before_filter :ensure_survey, :only => [:show]
  before_filter :check_survey_existence, :only => [:show, :clone, :destroy, :recover, :remove, :publish, :deadline, :close]

  def check_survey_existence
    @survey = Survey.user(current_user).find(params[:id] || params[:questionaire_id])
  end

  # PAGE: list survey
  # GET
  def index
    @surveys = current_user.surveys.title(params[:title]).status(params[:status]).star(params[:stars])
    @surveys = auto_paginate @surveys
    respond_to do |format|
      format.html { }
      format.json { render json: @surveys}
    end
  end

  # PAGE
  def new
    @survey = Survey.create
    current_user.surveys << @survey
    redirect_to questionaire_path(@survey._id) and return
  end

  # AJAX: clone survey
  def clone
    render_json_auto(@survey.clone_survey(current_user, params[:title])) and return
  end

  # PAGE: show and edit survey
  def show
    # @locked = (!current_user.is_admin? && @survey.publish_status == 8) 
  end

  # AJAX: delete survey
  def destroy
    render_json_auto(@survey.update_attributes(status: Survey::DELETED)) and return
  end

  # PUT
  def recover
    render_json_auto(@survey.update_attributes(status: Survey::CLOSED)) and return
  end

  #GET
  def remove
    render_json_auto(@survey.destroy) and return
  end

  # get
  def update_star
    render_json_auto @survey.update_attributes(is_star: params[:is_star].to_s == "true") and return
  end

  # AJAX: publish survey
  def publish
    render_json_auto(@survey.update_attributes(status: Survey::PUBLISHED)) and return
  end
  
  # AJAX: set deadline
  def deadline
    render_json_auto @survey.update_deadline(params[:deadline].to_i) and return
  end

  # AJAX: close a published survey
  def close
    render_json_auto(@survey.update_attributes(status: Survey::CLOSED)) and return
  end
end
