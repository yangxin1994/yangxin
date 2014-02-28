# already tidied up
class Client::SurveysController < Client::ApplicationController
  before_filter :require_client

  def index
    @surveys = current_client.surveys
  end

  def show
    @survey = Survey.find(params[:id])
    @interviewer_tasks = @survey.interviewer_tasks
    @answers = @interviewer_tasks.map { |e| e.answers } .flatten
    # @answers = @answers.select { |e| e.status == Answer::FINISHED }
    @answers = @answers.select { |e| e.status == Answer::FINISHED || e.status == Answer::UNDER_REVIEW }
    @location = @answers.map { |e| "#{e.latitude},#{e.longitude}" } .join('-')
  end
end
