class Admin::AgentTasksController < Admin::ApplicationController
	before_filter :check_agent_task_existence, :except => [:index, :create]

	def check_agent_task_existence
		@agent_task = AgentTask.normal.find_by_id(params[:id])
		render_json_e(ErrorEnum::AGENT_TASK_NOT_EXIST) and return if @agent_task.nil?
	end

	def index
		@agent_tasks = AgentTask.search_agent_task(params[:agent_id], params[:survey_id])
		@paginated_agent_tasks = auto_paginate(@agent_tasks) do |paginated_agent_tasks|
			paginated_agent_tasks.map { |e| e.info }
		end
		render_json_auto(@paginated_agent_tasks) and return
	end

	def create
		render_json_auto AgentTask.create_agent_task(params[:agent_task], params[:survey_id], params[:agent_id]) and return
	end

	def update
		render_json_auto @agent_task.update_agent_task(params[:agent_task]) and return
	end

	def close
		render_json_auto @agent_task.close and return
	end

	def open
		render_json_auto @agent_task.open and return
	end

	def destroy
		render_json_auto @agent_task.delete_agent_task and return
	end
end