class Box

  include Mongoid::Document

  field :title, :type => String
  field :wangpiao, :type => Integer, :default => 0
  field :hapiao, :type => Integer, :default => 0
  field :gewala, :type => Integer, :default => 0
  field :wanda, :type => Integer, :default => 0
  field :jinyi, :type => Integer, :default => 0
  field :taodianying, :type => Integer, :default => 0
  field :created_at, :type => Integer
  field :is_deleted, :type => Boolean, :default => false
  field :total, :type => Integer, :default => 0
  
  validates :created_at, presence: true

  before_create :check_exist

  after_create :bind_movie,:sum
  
  belongs_to :movie

  def check_exist
    if movie = Movie.where(:title => /#{title}/).first
      exist = movie.boxes.where(:created_at => self.created_at)
      if exist.present?
        exist.destroy
      end
    end
  end

  def bind_movie
    if movie = Movie.where(:title => /#{title}/).first
      movie.boxes << self
      movie.save
    end
  end

  def sum
    self.update_attributes(:total => (wangpiao + hapiao + gewala + wanda + jinyi + taodianying) )
  end

  def current_total(movie_id)
    movie = Movie.find(movie_id)
    movie.boxes.where(:created_at.lte => self.created_at).asc(:created_at).map{|e| e.total}.inject(0){|sum,ele| sum + ele}
  end

end