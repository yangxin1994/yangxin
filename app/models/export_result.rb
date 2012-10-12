 # encoding: utf-8
class ExportResult < Result
  include Mongoid::Document
  include Mongoid::Timestamps

  field :answer_content, :type => Hash
  field :filter_name, :type => String
  field :include_screened_answer, :type => Boolean
  field :last_updated_time, :type => Hash
  #field :process, :type => Integer
  def filtered_answers
  	Result.answers(self.survey, filter_name, include_screened_answer)
  end
end