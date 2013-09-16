# finish migrating
class Quill::QualitiesController < Quill::QuillController
  
  before_filter :ensure_survey

  # PAGE: show survey quality
  def show
    @quality_questions = QualityControlQuestion.list_quality_control_question(QualityControlQuestion::OBJECTIVE + QualityControlQuestion::MATCHING)
    @quality_control_questions_type = @survey.quality_control_questions_type || 0
    @quality_control_questions_ids = @survey.quality_control_questions_ids
  end

  # AJAX: update survey quality
  def update
    retval = @survey.update_quality_control(params[:quality_control_questions_type], params[:quality_control_questions_ids] || [])
    render_json_auto retval and return
  end
end