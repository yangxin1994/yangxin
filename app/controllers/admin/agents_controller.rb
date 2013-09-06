# encoding: utf-8

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
    @agent = Agent.create_agent(params[:agent])
    if @agent.created_at
      redirect_to admin_agents_path, :flash => {:success => "代理创建成功!"}
    else
      flash.alert = "代理创建失败, 请检查参数, 错误信息: #{result}"
      render :new
    end
  end

  def edit
    @agent = Agent.find(params[:id]).info
  end

  def update
    @agent = Agent.find(params[:id])
    if @agent.update_agent(params[:agent])
      redirect_to admin_agents_path, :flash => {:success => "代理创建成功!"}
    else
      flash.alert = "代理更新失败, 请检查参数, 错误信息: #{result}"
      render :json => result
    end
  end

  def destroy
    render_json @agent = Agent.where(:_id =>params[:id]).first do |agent|
      success_true agent.delete_agent
    end    
    
  end
end
