class Admin::SurveyTasksController < Admin::AdminController
  def index
    @survey_tasks = auto_paginate SurveyTask.search(params)
  end

  def show
  end

  def task_info
    survey = SurveyTask.find(params[:id])
    render_json_s survey.task_info and return
  end

  def create
  end

  def update
  end

  def destroy
  end
end
