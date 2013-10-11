class SmsHistory
  include Mongoid::Document
  include Mongoid::Timestamps
  include FindTool

  field :mobile, :type => String
  field :type, :type => String
  field :status, :type => String
  field :seqid, :type => Integer
end