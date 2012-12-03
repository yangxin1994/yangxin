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
  field :weight, :type => Integer, :default => 100000
  #field :prize_interval, :type => Array, :default => []

  default_scope where(:is_deleted => false).order_by(:created_at, :desc)

  scope :for_publish, where(:status => 0)
  scope :activity, where(:status => 1)
  scope :finished, where(:status => 2)
  
  has_many :surveys
  has_many :prizes
  has_many :lottery_codes
  has_many :gifts
  has_one :photo, :class_name => "Material", :inverse_of => 'lottery'
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
    base_num = 0
    r = random_weight
    interval = self.prizes.can_be_draw.map do |e|
      base_num += e.weight
      {
        :weight => base_num,
        :prize => e
      }
    end
    #logger.info "======#{interval}======="
    interval.each do |i|
      if r <= i[:weight]
        i[:prize].surplus -= 1
        i[:prize].save
        # lottery_code.update_attributes(
        #   :status => 2,
        #   :prize => i[:prize]
        #   )
        lottery_code.status = 2
        lottery_code.prize = i[:prize]
        # binding.pry
        lottery_code.prize.save
        lottery_code.save
        lottery_code[:prize] = i[:prize]
        return lottery_code
      end
    end
    lottery_code.update_attribute(:status, 1)
    lottery_code
  end

  def random_weight
    rand weight
  end

  def auto_draw
    self.lottery_codes.for_draw.each do |lc|
      self.draw lc
    end
  end

  def assign_prize(user, prize)
    lottery_code = give_lottery_code_to(user)
    lottery_code.prize = prize
    lottery_code.status = 2
    lottery_code.save
  end

  def make_interval
    prize_interval = [{ :weight => 0, :prize_id => nil }]
    self.prizes.can_be_draw.each do |a|
      prize_interval << { :weight => prize_interval[-1][:weight] + a.weight, :prize_id => a.id.to_s }
    end
    prize_interval
  end
  
end

