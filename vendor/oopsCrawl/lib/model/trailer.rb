class Trailer

  include Mongoid::Document

  field :title, :type => String
  field :trailer_id, :type => String
  field :created_at, :type => Integer

  belongs_to :movie

  has_many :comments, :class_name => "TrailerComment"

  validates :trailer_id, uniqueness: true, presence: true
  def rating
    nil
  end

end