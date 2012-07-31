class LotteryCode
	include Mongoid::Document
	include Mongoid::Timestamps
	extend Mongoid::FindHelper
	field :code, :type => String
	has_one :award
	belongs_to :order
	belongs_to :user
	belongs_to :lottery

end