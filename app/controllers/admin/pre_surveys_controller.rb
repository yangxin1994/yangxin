# encoding: utf-8
class Admin::PreSurveysController < Admin::AdminController

  layout "layouts/admin-todc"

  def index
    survey = Survey.find(params[:survey_id])
    @pre_surveys = survey.pre_surveys
  end

  def create
    survey = Survey.find(params[:survey_id])
    @pre_survey = Presurvey.create(params[:pre_survey])
    @presurvey.survey = survey
  end

  def destroy
    pre_survey = PreSurvey.find(params[:id])
    pre_survey.destroy
    redirect_to action: :index
  end

  def update
    pre_survey = PreSurvey.find(params[:id])
    pre_survey.update(params[:pre_survey])
  end
end
