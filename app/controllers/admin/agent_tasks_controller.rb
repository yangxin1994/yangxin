class Admin::AgentTasksController < Admin::ApplicationController
	before_filter :check_agent_task_existence, :except => [:index, :create]

	def check_agent_task_existence
		@agent_task = AgentTask.find_by_id(params[:id])
		if @agent_task.nil?
			render_json_e(ErrorEnum::AGENT_TASK_NOT_EXIST) and return
		end
	end

	def index
		@agent_tasks = AgentTask.search_agent()
		render_json_auto(auto_paginate(@agent_tasks)) and return
	end

	def create
		render_json_auto AgentTask.create_agent_task(params[:agent_task]) and return
	end

	def show
		render_json_auto @agent_task and return
	end

	def update
		render_json_auto @agent_task.update_agent_task(params[:agent_task]) and return
	end

	def destroy
		render_json_auto @agent_task.delete_agent_task and return
	end

	def reset_password
		render_json_auto @agent_task.reset_password(params[:password]) and return
	end

	def send_email
		render_json_auto @agent_task.send_email(params[:callback]) and return
	end
end