class Api::SurveyTasksController < ApplicationController
  def show
  end

  def create
    render_json SurveyTask.create(params) do |survey_task|
      survey_task
    end
  end

  def update
    render_json SurveyTask.find(params[:id]) do |survey_task|
      survey_task.update_attributes(params[:survey_task])
      survey_task
    end    
  end

  def destroy
    render_json SurveyTask.find(params[:id]) do |survey_task|
      survey_task.destroy
    end       
  end
end
