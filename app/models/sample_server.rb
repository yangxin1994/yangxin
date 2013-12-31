# encoding: utf-8
class SampleServer
  
  include Mongoid::Document
  include Mongoid::Timestamps
  include FindTool

  field :survey_id, :type => String
  field :survey_title, :type => String
  field :survey_url, :type => String
  field :survey_deadline, :type => Integer
  field :survey_quota, :type => Hash

end