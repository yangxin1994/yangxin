class Supervisor
  include Mongoid::Document
  include Mongoid::Timestamps
  include FindTool

  NORMAL  = 1
  DELETED = 0

  field :status,    :type => Integer,default:NORMAL
  has_and_belongs_to_many :surveys
  belongs_to :user


end
