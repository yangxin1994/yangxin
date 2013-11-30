# already tidied up
class Admin::AgentTasksController < Admin::AdminController
  layout "layouts/admin-todc"

  before_filter :require_sign_in, :only => [:index, :create, :update, :destroy]

  def index
    @agent_tasks = auto_paginate AgentTask.search_agent_task(params[:agent_id], params[:survey_id]) do |tasks|
      tasks.map { |e| e.info }
    end
  end

  def update
    render_json agent_task = AgentTask.where(:id => params[:id]).first do
      agent_task.update_agent_task(params[:agent_task])
    end
  end

  def close
    render_json agent_task = AgentTask.where(:id => params[:id]).first do
      agent_task.close
    end
  end

  def open
    render_json agent_task = AgentTask.where(:id => params[:id]).first do
      agent_task.open
    end
  end

  def destroy
    render_json agent_task = AgentTask.where(:id => params[:id]).first do
      agent_task.delete_agent_task
    end
  end

end