# encoding: utf-8
class ExportResult < Result
  include Mongoid::Document
  include Mongoid::Timestamps

  field :answer_content, :type => Hash
  field :last_updated_time, :type => Hash
  #field :process, :type => Integer

end