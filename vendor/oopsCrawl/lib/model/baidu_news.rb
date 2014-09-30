class BaiduNews

  include Mongoid::Document
  Nlpir::Mongoid.included(self)

  field :title       , :type => String
  field :sammary     , :type => String
  field :created_at  , :type => Integer
  field :created_hour, :type => Integer
  field :source      , :type => String
  field :url         , :type => String
  belongs_to :movie

  validates :created_at, presence: true

  before_save :g_created_hour

  def rating
    nil
  end

  def g_created_hour
    if created_hour.blank?
      self.created_hour = created_at - created_at % 3600
    end
  end

  def self.get_by_hour
    self.desc(:created_at).group_by{|bn| bn.created_hour}
  end
  
  def content
    sammary
  end
  
end