# encoding: utf-8
class ExportResult < Result
  include Mongoid::Document
  include Mongoid::Timestamps

  filed :spss_data, :type => Hash
  field :last_updated_time, :type => Hash

  def self.generate_result_key(spss_data)
    answer_ids = answers.map { |e| e.id_to_s }
    result_key = Digest::MD5.hexdigest("export_result-#{answer_ids.to_s}")
    return result_key
  end

  def self.find_or_create_by_filter_name(survey, filter_name, include_screened_answer)
    answers = self.answers(survey, filter_name, include_screened_answer)
    result_key = self.generate_result_key(answers)
    export_result = self.find_by_result_key(result_key)
    if export_result.nil?
      export_result = ExportResult.new(:result_key => result_key)
      # TODO 启动一次生成 记得设置 export_result.finished = true
      export_result.save
    end
    return export_result
  end

end