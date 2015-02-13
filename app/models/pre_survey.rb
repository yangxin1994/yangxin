require 'error_enum'
require 'securerandom'
class PreSurvey

  include Mongoid::Document
  include Mongoid::Timestamps
  include FindTool

  CLOSED = 1
  OPEN = 2

  EMAIL = 1
  MOBILE = 2

  field :name, :type => String
  # 1 for closed, 2 for open
  field :status, :type => Integer, default: 1
  field :publish, :type => Hash, default: { }
  field :conditions, :type => Array, default: [ ]
  field :last_scan_time, :type => Integer, default: 0
  field :reward_scheme_id, :type => String

  belongs_to :survey

end
