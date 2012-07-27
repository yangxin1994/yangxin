class Lottery
  include Mongoid::Document
  include Mongoid::Timestamps
  field :title, :type => String
  field :description, :type => String
  field :status, :type => Integer, :default => 1
  field :is_deleted, :type => Boolean, :default => false
  field :point, :type => Integer
  field :weighting, :type => Integer
  field :award_interval, :type => Array, :default => []
  field :amazing_time, :type => Array, :default => []

  default_scope where(:is_deleted => false)

  scope :unpublished, where(:status => 0)
  scope :published, where(:status => 1)
  scope :activity, where(:status => 2)
  scope :finished, where(:status => 3)
  
  #has_many :survey
  has_many :awards
  has_many :lottery_codes
  
  def delete
  	is_deleted = true
  	self.save
  end

  def add_an_award(attributes = nil, options = {}, &block)
  	self.awards.create(attributes, options, &block)
  end

  def add_a_lottery_code(attributes = nil, options = {}, &block)
    self.lottery_codes.create(attributes, options, &block)
  end

  def give_a_lottery_code_to(user)
    self.lottery_codes.create(:user => user)
  end

  def make_interval
    award_interval = []
    self.awards.can_be_draw.each do |a|
      award_interval << award_interval[-1] + a.weighting
    end
    self.update_attribute(:award_interval, ai)
  end

end
