# coding: utf-8
module Jobs

  class ToSpssJob
    @queue = :to_spss_queue

    def self.perform(survey_id, result_key)
      survey = Survey.find survey_id
      survey.to_spss_r(result_key)
      #survey.to_excel_r
    end

  end
end