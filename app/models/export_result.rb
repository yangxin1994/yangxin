class ExportResult < Result
  include Mongoid::Document
  include Mongoid::Timestamps

  field :answer_contents, :type => Array, :default => []
  field :filter_index, :type => Integer
  field :include_screened_answer, :type => Boolean
  field :last_updated_time, :type => Hash
  field :answers_count, :type => Integer
  field :export_process, :type => Hash, :default => { :answers => 0,
                                                      :post => 0,
                                                      :excel_convert => 0,
                                                      :spss_convert => 0}
  
  def self.find_or_create_by_result_key(result_key, survey)
    e = self.where(:result_key => result_key,
                   :survey_id => survey.id).first
    e.nil? ? self.create(:result_key => result_key, :survey =>survey) : e
  end

end       