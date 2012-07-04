class Order
	include Mongoid::Document
	include Mongoid::Timestamps
	# can be 0 (Cash), 1 (RealGoods), 2 (VirtualGoods), 3 (Lottery)
	field :type, :type => Integer
	# can be 0 (NeedVerify), 1 (Verified), -1 (VerifyFailed), 2 (Delivering), 3 (Delivered), -2 (DeliverFailed)
	field :status, :type => String
	# field :status_desc, :type => String
	field :recipient, :type => String
 	field :phone_number, :type => String

	scope :cash_order, ->{ where( :type => 0)}
	scope :realgoods_order, ->{ where( :type => 1)}
	scope :virtualgoods_order, ->{ where( :type => 2)}
	scope :lottery_order, ->{ where( :type => 3)}

	scope :need_verify, ->{ where( :status => 0)}
	scope :verified, ->{ where( :status => 1)}
	scope :verify_failed, ->{ where( :status => -1)}
	scope :delivering, ->{ where( :status => 2)}
	scope :delivered, ->{ where( :status => 3)}
	scope :deliver_failed, ->{ where( :status => -2)}


	scope :can_be_rewarded, ->{ where( :status => 1 ) }
	scope :expired_present, ->{ where( :status => 0 ) }

	embeds_one :cash_receive_info, :class_name => "CashReceiveInfo"
	embeds_one :realgoods_receive_info, :class_name => "RealgoodsReceiveInfo"
	embeds_one :virtualgoods_receive_info, :class_name => "VirtualgoodsReceiveInfo"
	embeds_one :lottery_receive_info, :class_name => "LotteryCodeReceiveInfo"
	has_one :point_log
	has_one :present
	belongs_to :user, :class_name => "User", :inverse_of => :orders
	belongs_to :operated_admin, :class_name => "User", :inverse_of => :operate_orders
	

	# TO DO validation verify




end

class CashReceiveInfo
	include Mongoid::Document
 	field :identification_card_number, :type => String
 	field :bank_name, :type => String
 	field :debit_card_number, :type => String
 	field :alipay, :type => String
	embedded_in :order
end

class RealgoodsReceiveInfo
	include Mongoid::Document
	field :address, :type => String
	field :post_code, :type => String
	embedded_in :order
end

class VirtualgoodsReceiveInfo
	include Mongoid::Document
	embedded_in :order
end

class LotteryCodeReceiveInfo
	include Mongoid::Document
	embedded_in :order
end

