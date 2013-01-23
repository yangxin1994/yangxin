class Lottery
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Mongoid::FindHelper
  include Mongoid::ValidationsExt
  include Mongoid::CriteriaExt

  field :title, :type => String
  field :description, :type => String
  # 0 0代表未发布 不显示, 1 代表显示未发布, 2代表发布不显示, 3代表显示并发布
  field :status, :type => Integer, :default => 0
  field :is_deleted, :type => Boolean, :default => false
  field :exchangeable, :type => Boolean, :default => false
  field :point, :type => Integer
  field :weight, :type => Integer, :default => 100000
  #field :prize_interval, :type => Array, :default => []

  default_scope order_by(:created_at => :desc)

  scope :for_publish, where(:status => 0).where(:is_deleted => false)
  scope :is_display, where(:status => 1).where(:is_deleted => false)
  scope :pause, where(:status => 2).where(:is_deleted => false)
  scope :activity, where(:status => 3).where(:is_deleted => false)
  scope :deleted, where(:is_deleted => true)
  # scope :quillme, where( '$or' => [:status => 1, :status => 3]).order_by(:status, :desc)
  scope :quillme, where('$or' => [{:status => 1}, {:status => 3}]).where(:is_deleted => false).order_by(:created_at => :desc)
 
  has_many :surveys
  has_many :answers
  has_many :prizes
  has_many :lottery_codes
  has_many :gifts
  has_one :photo, :class_name => "Material", :inverse_of => 'lottery'
  belongs_to :creator, :class_name => 'User'

  validates_presence_of :title
  validates_presence_of :point, :if => :exchangeable?

  def exchangeable?
    self.exchangeable
  end

  def photo_url
    if photo
      photo.picture_url
    else
      ""
    end
  end

  def exchange(user)
    return false if !exchangeable
    user.reward_logs.create(:type => 2,
      :point => -self.point,
      :cause => 6)
    self.give_lottery_code_to user, 0
    user.save
  end

  def present_quillme
    present_attrs :title, :description, :status, :exchangeable, :point, :created_at
    present_add :photo_src => self.photo.picture_url
    present_add :prizes => self.prizes.present_json('quillme')
  end

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

  def give_lottery_code_to(user, obtained_by = 2)
    self.lottery_codes.create(:user => user, :obtained_by => obtained_by)
  end

  def draw(lottery_code, auto = false)
    base_num = 0
    r = random_weight
    lprizes = auto ? self.prizes.can_be_autodraw : self.prizes.can_be_draw
    interval = lprizes.map do |e|
      base_num += self.weight / e.weight
      {
        :weight => base_num,
        :prize => e
      }
    end
    lottery_code.drawed_at = Time.now
    #logger.info "======#{interval}======="
    interval.each do |i|
      if r <= i[:weight]
        i[:prize].inc('surplus', -1)
        i[:prize].update_ctrl_surplus unless auto
        i[:prize].save
        # lottery_code.update_attributes(
        #   :status => 2,
        #   :prize => i[:prize]
        #   )
        lottery_code.status = 2
        lottery_code.prize = i[:prize]
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
    # self.prizes.can_be_autodraw.map do |prize|
    #   prize.update_attribute :ctrl_type, -1
    # end
    self.lottery_codes.for_draw.each do |lc|
      self.draw lc, true
    end
  end

  def assign_prize(user, prize)
    lottery_code = give_lottery_code_to(user)
    lottery_code.prize = prize
    lottery_code.status = 2
    lottery_code.drawed_at = Time.now
    lottery_code.prize.surplus -= 1
    lottery_code.prize.save
    lottery_code.save
  end

  def make_interval
    prize_interval = [{ :weight => 0, :prize_id => nil }]
    self.prizes.can_be_draw.each do |a|
      prize_interval << { :weight => prize_interval[-1][:weight] + a.weight, :prize_id => a.id.to_s }
    end
    prize_interval
  end

  def revive
    self.update_attribute :is_deleted, false
  end
  
end

