class Lottery
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, :type => String
  field :description, :type => String
  field :status, :type => Integer, :default => 0
  field :is_deleted, :type => Boolean, :default => false
  field :point, :type => Integer
  field :weighting, :type => Integer
  #field :award_interval, :type => Array, :default => []

  default_scope where(:is_deleted => false)

  scope :published, where(:status => 0)
  scope :activity, where(:status => 1)
  scope :finished, where(:status => 2)
  
  has_many :survey
  has_many :awards
  has_many :lottery_codes
  belongs_to :creator, :class_name => 'User'
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
        l.award = Award.find_by_id(e[:award_id])
        return l if (l.award.is_a?(Award)) && l.save 
        p l
      end
    end
    return false
  end

  def random_weighting
    rand weighting
  end

  def make_interval
    award_interval = [{ :weighting => 0, :award_id => nil }]
    self.awards.can_be_draw.each do |a|
      award_interval << { :weighting => award_interval[-1][:weighting] + a.weighting, :award_id => a.id.to_s }
    end
    award_interval
  end
  
end

