# encoding: utf-8

class Admin::AgentTasksController < Admin::AdminController
  layout "layouts/admin-todc"

  before_filter :require_sign_in, :only => [:index, :create, :update, :destroy]

  before_filter :get_agent_task_client

  def get_agent_task_client
    @agent_task_client = Admin::AgentTaskClient.new(session_info)
  end

  def index
    result = @agent_task_client.index(params)
    if result.success
      @agent_tasks = result.value
    else
      render :json => result
    end
  end

  def new
    result = @agent_task_client.new()
    if result[:success]
      @agent_task = result
    else
      render :json => result
    end
  end

  def create
    result = @agent_task_client.create(params[:new_agent_task])
    if result.success
      redirect_to "/admin/agent_tasks"
    else
      flash.alert = "代理创建失败, 请检查参数, 错误信息: #{result}"
      render :json => result
    end
  end

  def show
    
  end

  def close
    
  end

end