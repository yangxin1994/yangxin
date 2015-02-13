class Api::AnswerTasksController < ApplicationController
  def show
  end

  def create
    render_json AnswerTask.status_sync(params)
  end

  def update
    render_json AnswerTask.status_sync(params)
  end

  def destroy
  
  end
end
