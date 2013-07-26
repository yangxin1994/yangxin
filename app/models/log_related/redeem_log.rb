# encoding: utf-8
class RedeemLog < Log
	field :type, :type => Integer, :default => 4
	field :amount, :type => Integer
	field :order_id, :type => String
	field :gift_id, :type => String
	field :gift_name, :type => String

	def self.create_gift_exchange_logs(amount,order_id,gift_id,user_id)
		gift_name = Gift.find_by_id(gift_id).title
		self.create(:amount => amount,:order_id => order_id,:gift_id => gift_id,:gift_name => gift_name,:user_id => user_id)
	end

end
