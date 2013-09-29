class ToSpssWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false, :queue => "oopsdata_#{Rails.env}".to_sym

  def perform(survey_id, analysis_task_id, task_id)
    survey = Survey.find_by_id(survey_id)
    return false if survey.nil?
    data_list = AnalysisResult.get_data_list(analysis_task_id)
    return false if data_list == ErrorEnum::RESULT_NOT_EXIST
    answer_info = data_list[:answer_info] || []
    answers = answer_info.map { |e| Answer.find_by_id e["_id"] }
    # generate result key
    result_key = ExportResult.generate_spss_result_key(survey.last_update_time,answers)
    existing_export_result = ExportResult.find_by_result_key(result_key)
    if existing_export_result.nil?
      # create new result record
      export_result = ExportResult.create(:result_key => result_key,:task_id => task_id)
    else
      export_result = ExportResult.create(
        :result_key => result_key,
        :task_id => task_id,
        :ref_result_id => existing_export_result._id
      )
      return true
    end
    survey.export_results << export_result
    retval = export_result.generate_spss(survey, answers, result_key)
    return true
  end
end
