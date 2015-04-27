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
    puts("answers_length:-----------#{answers.length}")
    # generate result key
    result_key = ExportResult.generate_spss_result_key(survey.last_update_time,answers)
    puts '1'
    existing_export_result = ExportResult.find_by_result_key(result_key)
    puts '2'
    if existing_export_result.nil?
      puts '3'
      # create new result record
      export_result = ExportResult.create(:result_key => result_key,:task_id => task_id)
      puts export_result.inspect
    else
      puts '4'
      export_result = ExportResult.create(
        :result_key => result_key,
        :task_id => task_id,
        :ref_result_id => existing_export_result._id
      )
      puts export_result.inspect
      return true
    end
    puts '5'
    survey.export_results << export_result
    puts '6'
    retval = export_result.generate_spss(survey, answers, result_key)
    puts '7'
    return true
  end
end
