class LotteryCode
	include Mongoid::Document
	include Mongoid::Timestamps
	extend Mongoid::FindHelper

	field :code, :type => String
	field :email, :type => String
	has_one :award
	belongs_to :order
	belongs_to :user
	belongs_to :lottery


	def draw
		self.lottery.draw(self.id)
	end

end