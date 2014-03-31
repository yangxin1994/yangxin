class Admin::SurveyTasksController < Admin::AdminController
  def index
    @survey_tasks = auto_paginate SurveyTask.all
  end

  def show
  end

  def create
  end

  def update
  end

  def destroy
  end
end
