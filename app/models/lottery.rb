class Lottery
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, :type => String
  field :description, :type => String
  field :status, :type => Integer, :default => 1
  field :is_deleted, :type => Boolean, :default => false
  field :point, :type => Integer
  field :weighting, :type => Integer
  #field :award_interval, :type => Array, :default => []

  default_scope where(:is_deleted => false)

  scope :unpublished, where(:status => 0)
  scope :published, where(:status => 1)
  scope :activity, where(:status => 2)
  scope :finished, where(:status => 3)
  
  #has_many :survey
  belongs_to :awards
  has_many :lottery_codes
  #has_many :lottery_awards, :class_name => 'LotteryAward'

  def delete
  	is_deleted = true
  	self.save
  end

  def add_an_lottery_award(attributes = nil, options = {}, &block)
  	self.lottery_awards.create(attributes, options, &block)
  end

  def add_a_lottery_code(attributes = nil, options = {}, &block)
    self.lottery_codes.create(attributes, options, &block)
  end

  def give_a_lottery_code_to(user)
    self.lottery_codes.create(:user => user)
  end

  def draw(lottery_code)
    r = random_weighting
    l = LotteryCode.find_by_id(lottery_code)
    make_interval.each do |e|
      if r < e[:weighting]
        return l unless l.is_a? LotteryCode
        l.award = Award.find_by_id(e[:award])
        return l if (l.award.is_a?(Award)) && l.save 
      end
    end
    return false
  end

  def random_weighting
    rand weighting
  end

  def make_interval
    award_interval = [{ :weighting => 0, :award => nil }]
    self.awards.can_be_draw.each do |a|
      award_interval << { :weighting => award_interval[-1][:weighting] + a.weighting, :award => a.id.to_s }
    end
    award_interval
  end
  
end

