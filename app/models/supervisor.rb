class Supervisor
  include Mongoid::Document
  include Mongoid::Timestamps
  include FindTool

  NORMAL  = 1
  DELETED = 0

  field :status,    :type => Integer,default:NORMAL

  belongs_to :survey
  belongs_to :user


end
