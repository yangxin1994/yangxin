# finish migrating
require 'error_enum'
class Quill::PagesController < ApplicationController
  
  before_filter :require_sign_in, :except => [:show]
  before_filter :ensure_survey

  def ensure_survey
    @survey = Survey.find_by_id(params[:questionaire_id])
    render_json_e ErrorEnum::SURVEY_NOT_EXIST and return if @survey.nil?
  end

  # create page
  def create
    render_json_auto @survey.create_page(params[:page_index].to_i, 'new page')
  end

  # split one page into two pages.
  # If before_question_id is -1, split at the last of the page.
  def split
    render_json_auto @survey.split_page(params[:id].to_i, params[:before_question_id], 'new page', 'new page')
  end

  # combine pages
  def combine
    render_json_auto @survey.combine_pages(params[:id].to_i, params[:id].to_i + 1)
  end

  # get one page questions
  def show
    render_json_auto @survey.show_page(params[:id].to_i)
  end
end
