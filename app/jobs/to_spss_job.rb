# coding: utf-8
module Jobs

  class ToSpssJob
    @queue = :to_spss_queue

    def self.perform(result_key)
      #survey = Survey.find survey_id
      #survey.to_spss_r(result_key)
      #result = Result.find_by_result_key result_key
      #result.to_spss

      result = ExportResult.find_by_result_key(result_key)
      result.to_spss
      #survey.to_excel_r
    end

  end
end