class Admin::AgentsController < Admin::ApplicationController

	before_filter :check_agent_existence, :only => [:show, :update, :destroy]

	def check_agent_existence
		@agent = Agent.find_by_id(params[:id])
		render_json_auto ErrorEnum::AGENT_NOT_EXIST if @agent.nil?
	end

	def index
		agents = Agent.search_agent(params[:email], params[:region])
		render_json_auto(auto_paginate(agents){|agents| agents.map { |e| e.info } }) and return
	end

	def show
		render_json_auto(@agent.info) and return
	end

	def create
		render_json_auto Agent.create_agent(params[:agent]) and return
	end

	def update
		render_json_auto @agent.update_agent(params[:agent]) and return
	end

	def destroy
		render_json_auto @agent.delete_agent and return
	end
end