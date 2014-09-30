class Review

  include Mongoid::Document
  Nlpir::Mongoid.included(self)
  

  field :title, :type => String
  field :user_name, :type => String
  field :content, :type => String
  field :created_at, :type => Integer
  field :review_id, :type => String
  field :votes, :type => Integer
  field :rating, :type => Integer
  
  belongs_to :movie
  has_many :comments, :class_name => "ReviewComment"

  validates :created_at, presence: true
  validates :review_id, presence: true, uniqueness: true

  def review_url
    "http://movie.douban.com/review/#{review_id}/"
  end

end