class Quill::QuillController < ApplicationController
  
  before_filter :require_sign_in

  def initialize(step = 1)
    @current_step = step
    super()
  end

  def ensure_survey
    return @survey if @survey
    @survey = Survey.find_by_id(params[:questionaire_id])
    return
  end

  def get_survey_questions
    ensure_survey
    survey_questions = { :pages => [] }
    # page_client = Quill::PageClient.new(session_info, @survey['_id'])
    (@survey.pages || []).each_with_index do |page, i|
      result = @survey.show_page(i)
      survey_questions[:pages] << result if result.class != "String"
    end
    return survey_questions
  end
end