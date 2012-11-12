class Lottery
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Mongoid::FindHelper
  include Mongoid::ValidationsExt
  field :title, :type => String
  field :description, :type => String
  # 0 (for_publish) 1 (activity) 2 (finished)
  field :status, :type => Integer, :default => 0
  field :is_deleted, :type => Boolean, :default => false
  #field :point, :type => Integer
  field :weighting, :type => Integer, :default => 10000
  #field :prize_interval, :type => Array, :default => []

  default_scope where(:is_deleted => false)

  scope :for_publish, where(:status => 0)
  scope :activity, where(:status => 1)
  scope :finished, where(:status => 2)
  
  has_many :survey
  has_many :prizes
  has_many :lottery_codes
  has_many :gifts
  belongs_to :creator, :class_name => 'User'

  def delete
  	is_deleted = true
  	self.save
  end

  def add_prezi(attributes = nil, options = {}, &block)
  	self.lottery_prizes.create(attributes, options, &block)
  end

  def add_lottery_code(attributes = nil, options = {}, &block)
    self.lottery_codes.create(attributes, options, &block)
  end

  def give_lottery_code_to(user)
    self.lottery_codes.create(:user => user)
  end

  def draw(lottery_code)
    r = random_weighting
    l = LotteryCode.find_by_id(lottery_code)
    make_interval.each do |e|
      if r < e[:weighting]
        return l unless l.is_a? LotteryCode
        l.prize = Prezi.find_by_id(e[:prize_id])
        return l if (l.prize.is_a?(Prize)) && l.save 
      end
    end
    return false
  end

  def random_weighting
    rand weighting
  end

  def make_interval
    prize_interval = [{ :weighting => 0, :prize_id => nil }]
    self.prizes.can_be_draw.each do |a|
      prize_interval << { :weighting => prize_interval[-1][:weighting] + a.weighting, :prize_id => a.id.to_s }
    end
    prize_interval
  end
  
end

