class Carnival::AgentsController < Carnival::CarnivalController

  def index
    agent_name = params[:daili]
    cs = CarnivalUser.where(source: agent_name)

    @sample_num = cs.select { |e| e.survey_status.include?(32) || e.survey_status.include?(4) || e.survey_status.include?(2) } .length
    @finish_num = cs.select { |e| !e.survey_status.include?(0) && !e.survey_status.include?(4) && !e.survey_status.include?(2) } .length
    @finish_mobile = cs.select { |e| !e.survey_status.include?(0) && !e.survey_status.include?(4) && !e.survey_status.include?(2) } .map { |e| e.mobile } .join(', ')
    @reject_mobile = cs.select { |e| e.survey_status.include?(2) && e.mobile.present? } .map { |e| e.mobile } .join(', ')
    render layout: false
  end
end
