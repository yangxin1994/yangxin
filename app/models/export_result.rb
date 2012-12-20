class ExportResult < Result
  include Mongoid::Document
  include Mongoid::Timestamps

  field :answer_contents, :type => Array, :default => []
  field :file_uri, :type => String
  
  def self.generate_excel_result_key(answers)
    answer_ids = answers.map { |e| e._id.to_s }
    result_key = Digest::MD5.hexdigest("to_excel_result-#{answer_ids.to_s}")
    return result_key
  end

end