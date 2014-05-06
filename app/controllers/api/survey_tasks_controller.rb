class Api::SurveyTasksController < ApplicationController
  def show
    render_json SurveyTask.where(:identifier => params[:id]).first do |survey_task|
      {
        quillme_promotable: survey_task.quillme_promotable
      }
    end
  end

  def create
    render_json SurveyTask.create(params[:survey_task]) do |survey_task|
      survey_task
    end
  end

  def update
    render_json SurveyTask.where(:_id => params[:id]).first do |survey_task|
      survey_task.update_attributes(params[:survey_task])
      survey_task
    end    
  end

  def destroy
    render_json SurveyTask.where(:_id => params[:id]).first do |survey_task|
      survey_task.destroy
    end       
  end
end
