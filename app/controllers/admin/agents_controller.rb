class Admin::AgentsController < Admin::AdminController

  layout "layouts/admin-todc"

  before_filter :require_sign_in, :only => [:index, :create, :update, :destroy]

  def index
    @agents = auto_paginate Agent.search_agent(params[:email], params[:region]) do |agents|
      agents.map { |e| e.info }
    end
  end


  def new
    @agent = {}
  end

  def create
    @agent = Agent.create(params[:agent])
    if @agent.created_at
      redirect_to admin_agents_path
    else
      render :new
    end
  end

  def edit
    @agent = Agent.find(params[:id]).info
  end

  def update
    @agent = Agent.find(params[:id])
    if @agent.update_agent(params[:agent])
      redirect_to admin_agents_path
    else
      render :json => result
    end
  end

  def destroy
    render_json @agent = Gift.where(:_id =>params[:id]).first do |agent|
      success_true agent.delete_agent
    end    
    
  end
end
