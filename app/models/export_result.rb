# encoding: utf-8
class ExportResult < Result
  include Mongoid::Document
  include Mongoid::Timestamps


  def initialize(filter_name, survey)
    super
    # self.survey = survey
    # result_key = generate_result_key(survey.answers)
    # #export_result = ExportResult.where(:result_key => result_key).first
    # if export_result.nil?
    #   survey.filter_name = filter_name
    #   survey.send_spss_data
    #   self.save
    #   return self
    # else
    #   return export_result
    # end
  end

  def self.generate_result_key(answers)
    answer_ids = answers.map { |e| e._id.to_s }
    result_key = Digest::MD5.hexdigest("export_result-#{answer_ids.to_s}")
    return result_key
  end
  
end