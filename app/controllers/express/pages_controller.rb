require 'error_enum'
class Express::PagesController < Express::ExpressController
  
  before_filter :require_sign_in, :except => [:show]
  before_filter :ensure_survey

  def ensure_survey
    @survey = Survey.find_by_id(params[:questionaire_id])
  end

  def create
    render_json_auto @survey.create_page(params[:page_index].to_i, 'new page')
  end

  def split
    render_json_auto @survey.split_page(params[:id].to_i, params[:before_question_id], 'new page', 'new page')
  end

  def combine
    render_json_auto @survey.combine_pages(params[:id].to_i, params[:id].to_i + 1)
  end

  def show
    render_json_auto @survey.show_page(params[:id].to_i)
  end
end
