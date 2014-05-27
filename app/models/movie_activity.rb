require 'error_enum'
require 'securerandom'
class MovieActivity

  include Mongoid::Document
  include Mongoid::Timestamps
  include FindTool

  NOT_EXIST = 0
  EDIT = 1
  REJECT = 2
  FINISH = 32

  # 0 for not exist, 1 for edit, 2 for reject, 32 for finish
  field :pre_survey_status, type: Integer, default: 0
  field :survey_status, type: Array, default: Array.new(15) { 0 }
  field :reward_status, type: Array, default: Array.new(3) { 0 }

  belongs_to :user
  has_many :orders

end
