#already tidied up
class EmailHistory
  include Mongoid::Document
  include Mongoid::Timestamps
  field :success, :type => Boolean
  field :email, :type => String
  # 0 for ongoing, 1 for finished
  field :status, :type => Integer, default: 0
  belongs_to :user
  belongs_to :survey, index: true
  index({ survey_id: 1 }, { background: true } )
end
