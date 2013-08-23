class Agent::AnswersController < Agent::AgentsController

  def index
    agent_task = current_agent.agent_tasks.where(:id => params[:agent_task_id]).first

    @answers = auto_paginate agent_task.answers do |answers|
      answers.map { |e| e.info_for_auditor }
    end

  end

  def show
    agent_task = current_agent.agent_tasks.find(params[:agent_task_id])
    @questions = agent_task.answers.find(params[:id]).present_auditor
  end

  def review
    result = @answer_client.review(params)
    if result.success
      @questions = result.value
    else
      render :json => result
    end
  end
  def update
    render_json Answer.find(params[:id]) do |answer|
      answer.agent_review(params[:review_result].to_s == "true")
    end 
  end
end