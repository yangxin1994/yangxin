class LotteryCode
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Mongoid::FindHelper
  include Mongoid::ValidationsExt
  include Mongoid::CriteriaExt

  field :num, :type => Integer, default: 0
  # 0 为积分兑换, 1 为通过答题获取, 2 为系统添加
  field :obtained_by , :type => Integer
  field :code, :type => String
  field :email, :type => String
<<<<<<< HEAD
  # 0 (待抽奖) 1 (未中奖) 2 (中奖未下订单) 4(中奖已下订单)
=======
  # 0 (待抽奖) 1 (未中奖) 2 (中奖未下订单) 4(中奖已下订单)
>>>>>>> fb3fc4d8ab163a59fda0736138b43684d5a55841
  field :status, :type => Integer, default: 0
  field :drawed_at, :type => Time

  belongs_to :prize
  has_one :order
  belongs_to :user
  belongs_to :lottery
  belongs_to :reward_log

  delegate :title, :status, :photo_url , :exchangeable, :description, :to => :lottery, :prefix => true

  default_scope order_by(:updated_at.desc)

  scope :for_draw, where(:status => 0)
  scope :drawed, where(:status.gt => 0).order_by(:drawed_at.desc)
  scope :drawed_f, where(:status => 1).order_by(:drawed_at.desc)
  scope :drawed_w, where(:status.gt => 1).order_by(:drawed_at.desc)
  scope :drawed_w_n, where(:status => 2).order_by(:drawed_at.desc)
  scope :drawed_w_o, where(:status => 4).order_by(:drawed_at.desc)

  validates :num, :numericality => { :greater_than_or_equal_to => 0 }

  index({ status: 1 }, { background: true } )

  def draw
    self.lottery.draw(self) #unless self.status > 0
  end

  def present_quillme
    present_attrs :drawed_at, :created_at, :status, :_id
    present_add :order_id => self.order._id if self.order
    if self.prize
      present_add(:prize_name => self.prize.name)
      present_add(:prize_name => self.prize.name)
    end
    present_add :for_lottery =>
      { :title => self.lottery_title,
        :status => self.lottery_status,
        :photo_src => self.lottery_photo_url,
        :exchangeable => self.lottery_exchangeable,
        :description => self.lottery_description
      }
  end

  def present_admin
    present_attrs :drawed_at, :created_at, :status, :_id
    present_add :user => self.user
    present_add :prize => self.prize
  end

  def present_quillme_draws
    present_attrs :drawed_at, :created_at, :status, :_id
    present_add :order_id => self.order._id if self.order
    present_add :prize => self.prize.present_quillme if self.prize
    present_add :lottery_status => self.lottery.status
  end
end
