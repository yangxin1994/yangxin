class Admin::AnswerAuditorsController < Admin::ApplicationController

  def index
    answer_auditors = User.find_answer_auditors
    render_json_auto answer_auditors and return
  end
end