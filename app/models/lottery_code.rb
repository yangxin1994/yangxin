
class LotteryCode
	include Mongoid::Document
	include Mongoid::Timestamps
	extend Mongoid::FindHelper
	include Mongoid::ValidationsExt

	field :num, :type => Integer, default: 0
	field :code, :type => String
	field :email, :type => String
	has_one :prize
	belongs_to :order
	belongs_to :user
	belongs_to :lottery

	validates :num, :numericality => { :greater_than_or_equal_to => 0 }

	def draw
		self.lottery.draw(self.id)
	end

end
