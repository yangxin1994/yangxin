# finish migrating
class Quill::FiltersController < Quill::QuillController
  
  before_filter :ensure_survey

  def initialize
    super(4)
  end
  
  # PAGE: index survey filters
  def index
    @survey_questions = get_survey_questions
  end

  # PAGE: show survey filter
  def show
    @survey_questions = get_survey_questions
    @current_filter = @survey.show_filter(params[:id])
    @current_index = @current_filter.nil? ? -1 : params[:id].to_i
  end

  # AJAX: destory a filter by its index
  def destroy
    render_json_auto @survey.delete_filter(params[:id].to_i) and return
  end

  # AJAX: update filter by its index
  def update
    render_json_auto @survey.update_filter(params[:id].to_i, params[:filter]) and return
  end

  # AJAX: create a new filter
  def create
    render_json_auto @survey.add_filter(params[:filter]) and return
  end
end