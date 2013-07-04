# encoding: utf-8
require 'encryption'
require 'error_enum'
require 'tool'
class Agent::SessionsController < Agent::ApplicationController

	before_filter :require_agent_task, :only => [:reset_password]

	def create
		login = AgentTask.login(params[:agent_task]["email"], params[:agent_task]["password"], params[:survey_id])
		render_json_auto(login) and return
	end

	def destroy
		AgentTask.logout(params[:id])
		render_json_s and return
	end

	def reset_password
		retval = @agent_task.reset_password(params[:old_password], params[:new_password])
		render_json_auto(retval) and return
	end

	def login_with_auth_key
		retval = AgentTask.login_with_auth_key(params[:auth_key])
		render_json_auto(retval) and return
	end
end
