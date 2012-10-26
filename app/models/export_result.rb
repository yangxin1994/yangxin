class ExportResult < Result
  include Mongoid::Document
  include Mongoid::Timestamps

  field :answer_contents, :type => Array, :default => []
  field :data_list_result_id, :type => String
  field :answers_count, :type => Integer
  field :export_process, :type => Hash, :default => { :answers => 0,
                                                      :post => 0,
                                                      :excel_convert => 0,
                                                      :spss_convert => 0}

  def self.find_by_data_list_result(result_key, survey)
    e = self.where(:result_key => result_key,
                   :survey_id => survey.id).first
    e.nil? ? self.create(:result_key => result_key, :survey =>survey) : e
  end

  def self.generate_excel_result_key(answers)
    answer_ids = answers.map { |e| e._id.to_s }
    result_key = Digest::MD5.hexdigest("to_excel_result-#{answer_ids.to_s}")
    return result_key
  end

end