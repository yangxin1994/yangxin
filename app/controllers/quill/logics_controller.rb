class Quill::LogicsController < Quill::QuillController
  
  before_filter :ensure_survey

  # PAGE: index survey logics
  def index
    @survey_questions = get_survey_questions
  end

  # PAGE: show survey logic
  def show
    @survey_questions = get_survey_questions
    @current_logic = @survey.show_logic_control_rule(params[:id])
    @current_index = @current_logic.nil? ? -1 : params[:id].to_i
  end

  # AJAX: destory a logic by its index
  def destroy
    render_json_auto @survey.delete_logic_control_rule(params[:id].to_i) and return
  end

  # AJAX: update s logic by its index
  def update
    render_json_auto @survey.update_logic_control_rule(params[:id].to_i, params[:logic]) and return
  end

  # AJAX: create a new logic
  def create
    render_json_auto @survey.add_logic_control_rule(params[:logic]) and return
  end
end