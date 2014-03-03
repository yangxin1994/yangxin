class Filler::SurveysController < Filler::FillerController

  # PAGE
  def show
    @info_not_complete = (current_user.present? && current_user.completed_info < 100)
    load_survey(params[:id])
  end
end