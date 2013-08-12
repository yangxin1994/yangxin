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
		gift = Gift.find_by_id(gift_id)
		case gift.type
		when Gift::MOBILE_CHARGE
			gift_name = "#{amount}元话费"
		when Gift::ALIPAY
			gift_name = "#{amount}元支付宝"
		when Gift::JIFENBAO
			gift_name = "#{amount}集分宝"
		when Gift::QQ_COIN
			gift_name = "#{amount}元Q币"
		when Gift::REAL
			gift_name = gift.try(:title)
		end

		self.create(:amount => amount,:point => point,:gift_type => gift_type,:order_id => order_id,:gift_id => gift_id,:gift_name => gift_name,:user_id => user_id)
	end

	def info_for_admin
		redeem_log_obj = {}
		redeem_log_obj["created_at"] = self.created_at.to_i
		redeem_log_obj["amount"] = self.amount.to_s
		redeem_log_obj["order_id"] = self.order_id
		redeem_log_obj["gift_name"] = self.gift_name
		return redeem_log_obj
	end

end
