class LotteryCode
	include Mongoid::Document
	include Mongoid::Timestamps
	extend Mongoid::FindHelper
	include Mongoid::ValidationsExt

	field :num, :type => Integer, default: 0
	field :code, :type => String
	field :email, :type => String
	# 0 (待抽奖) 1 (未中奖) 2 (中奖未下订单) 4(中奖已下订单) 
	field :status, :type => Integer, default: 0

	has_one :prize
	has_one :order
	belongs_to :user
	belongs_to :lottery

	scope :for_draw, where(:status => 0)
	scope :drawed, where(:status.gt => 0)
	scope :drawed_f, where(:status => 1)
	scope :drawed_w, where(:status.gt => 1)
	scope :drawed_w_n, where(:status => 2)
	scope :drawed_w_o, where(:status => 4)

	validates :num, :numericality => { :greater_than_or_equal_to => 0 }

	def draw
		self.lottery.draw(self)
	end

	

end
