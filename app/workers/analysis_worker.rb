# encoding: utf-8
class AnalysisWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false, :queue => "oopsdata_#{Rails.env}".to_sym

  def perform(survey_id, filter_index, include_screened_answer, task_id)
    # get the survey instance
    survey = Survey.find_by_id(survey_id)
    return false if survey.nil?
    # find answers set
    answers, tot_answer_number, screened_answer_number, ongoing_answer_number, wait_for_review_answer_number = *survey.get_answers(
      filter_index.to_i,
      include_screened_answer.to_s == "true",
      task_id)
    # generate the result_key
    result_key = AnalysisResult.generate_result_key(
      survey.last_update_time,
      answers,
      tot_answer_number,
      screened_answer_number,
      ongoing_answer_number,
      wait_for_review_answer_number)
    existing_analysis_result = AnalysisResult.find_by_result_key(result_key)
    if existing_analysis_result.nil?
        # create analysis result
        analysis_result = AnalysisResult.create(
          :result_key => result_key,
          :task_id => task_id,
          :tot_answer_number => tot_answer_number,
          :screened_answer_number => screened_answer_number,
          :ongoing_answer_number => ongoing_answer_number,
          :wait_for_review_answer_number => wait_for_review_answer_number)
    else
        # create analysis result
        analysis_result = AnalysisResult.create(
          :result_key => result_key,
          :task_id => task_id,
          :tot_answer_number => tot_answer_number,
          :screened_answer_number => screened_answer_number,
          :ref_result_id => existing_analysis_result._id,
          :ongoing_answer_number => ongoing_answer_number,
          :wait_for_review_answer_number => wait_for_review_answer_number)
        return true
    end
    survey.analysis_results << analysis_result
    # analyze and save the analysis result
    analysis_result.analysis(answers, task_id)
    return true
  end
end
