class Quill::QuotasController < Quill::QuillController
  before_filter :ensure_survey
  
  def destroy
    render_json_auto @survey.delete_quota_rule(params[:id].to_i)
  end

  def update
    render_json_auto @survey.update_quota_rule(params[:id].to_i, params[:quota])
  end

  def create
    render_json_auto @survey.add_quota_rule(params[:quota])
  end

  def refresh
    render_json_auto @survey.refresh_quota_stats
  end
end