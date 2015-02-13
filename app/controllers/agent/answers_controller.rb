# encoding: utf-8
class Agent::AnswersController < Agent::AgentsController

  def index
    agent_task = current_agent.agent_tasks.where(:id => params[:agent_task_id]).first

    @answers = auto_paginate agent_task.answers.search(params) do |answers|
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

  def to_csv
    agent_task = current_agent.agent_tasks.find(params[:id])
    answers = agent_task.answers.search(params)
    survey = agent_task.survey
    csv_string = survey.agent_to_csv(answers)
    csv_string_gbk = ""
    csv_string.each_char do |csv_str|
      begin
        csv_string_gbk << csv_str.encode("GBK")
      rescue
        csv_string_gbk << ' '
      end
    end
    send_data(csv_string_gbk,
      :filename => "答案数据-#{Time.now.strftime("%M-%d_%T")}.csv",
      :type => 'text/csv')
  end
end
