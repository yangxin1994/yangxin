class TrailerComment

  include Mongoid::Document
  Nlpir::Mongoid.included(self)
  

  field :user_name, :type => String
  field :content, :type => String
  field :created_at, :type => Integer

  belongs_to :trailer

  validates :created_at, presence: true
  def rating
    nil
  end

end