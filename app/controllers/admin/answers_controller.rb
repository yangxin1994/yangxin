class Admin::AnswersController < Admin::AdminController

  layout "layouts/admin-todc"

  before_filter :require_sign_in, :only => [:index, :create, :update, :destroy]

  before_filter :get_answer_client

  def get_answer_client
    @answer_client = Admin::AnswerClient.new(session_info)
  end

  def index
    result = @answer_client.index(params)
    if result.success
      @surveys = result.value
    else
      render :json => result
    end
  end

  def show
    result = @answer_client.show(params)
    if result.success
      @answers = result.value
    else
      render :json => result
    end
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
    render :json => @answer_client.update(params) 
  end

end