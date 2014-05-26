# encoding: utf-8
class Admin::PreSurveysController < Admin::AdminController

  layout "layouts/admin-todc"

  def index
    survey = Survey.find(params[:_id])
    @presurvey_schemes = survey.pre_surveys
    @editing_ps = PreSurvey.where(:_id => params[:editing]).first || {}
    gon.push({
      :editing => @editing_ps
      })
    @surveys = Survey.normal
  end

  def create
    survey = Survey.find(params[:_id])
    format_params
    @pre_survey = PreSurvey.create(params[:pre_survey])
    @pre_survey.survey = survey
    render_json @pre_survey.save
  end

  def destroy
    pre_survey = PreSurvey.find(params[:id])
    pre_survey.destroy
    redirect_to action: :index
  end

  def update
    pre_survey = PreSurvey.find(params[:id])
    format_params
    render_json pre_survey.update_attributes(params[:pre_survey])
  end

  def format_params
    params[:pre_survey][:conditions] = params[:pre_survey][:conditions].map do |k, v| 
      v.map do |k, v|
        v["fuzzy"] = v["fuzzy"] == "fuzzy"
        v
      end
    end
  end

  def questions
    questions = []
    surveys = Survey.where(:_id.in => params[:survey_ids].split('|'))
    # stype = (params["stype"]||"0").split('|').map { |e| e.to_i }
    stype = [4, 6]
    email_questions = surveys.map do |survey|
      survey.all_questions.select{|question| stype.include? question["question_type"]}
    end.flatten
    stype = [0]
    choice_questions = surveys.map do |survey|
      survey.all_questions.select{|question| stype.include? question["question_type"]}
    end.flatten
    render_json true do 
      {
        email_questions: email_questions,
        choice_questions: choice_questions
      }
    end
  end
end
