# encoding: utf-8
class RedeemLog < Log
	field :type, :type => Integer, :default => 4
	field :amount, :type => Integer
	field :order_id, :type => String
	field :point,:type => Integer
	field :gift_id, :type => String
	field :gift_type,:type => Integer
	field :gift_name, :type => String

	def self.create_gift_exchange_logs(amount,point,gift_type,order_id,gift_id,user_id)
		gift_name = Gift.find_by_id(gift_id).title
		self.create(:amount => amount,:point => point,:gift_type => gift_type,:order_id => order_id,:gift_id => gift_id,:gift_name => gift_name,:user_id => user_id)
	end

end
