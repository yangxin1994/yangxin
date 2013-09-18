# finish migrating
class Quill::LogicsController < Quill::QuillController
  
  before_filter :ensure_survey

  # PAGE: index survey logics
  def index
    @survey_questions = get_survey_questions
  end

  # PAGE: show survey logic
  def show
    @survey_questions = get_survey_questions
    logics = @survey.logic_control || []
    @current_index = -1
    @current_logic = nil
    index = params[:id].to_s
    if index.to_i.to_s == index
      index = index.to_i
      if index >= 0 && index < logics.length
        @current_index = index
        @current_logic = logics[index]
      end
    end
  end

  # AJAX: destory a logic by its index
  def destroy
    retval = @survey.delete_logic_control_rule(params[:id].to_i)
    render_json_auto retval and return
  end

  # AJAX: update s logic by its index
  def update
    retval = @survey.update_logic_control_rule(params[:id].to_i, params[:logic])
    render_json_auto retval and return
  end

  # AJAX: create a new logic
  def create
    retval = @survey.add_logic_control_rule(params[:logic])
    render_json_auto retval and return
  end
end