class Order
	include Mongoid::Document
	include Mongoid::Timestamps
	include Mongoid::ValidationsExt
	extend Mongoid::FindHelper
	# can be 0 (Cash), 1 (RealGoods), 2 (VirtualGoods), 3 (Lottery)
	field :type, :type => Integer
	# can be 0 (NeedVerify), 1 (Verified), -1 (VerifyFailed), 2 (Delivering), 3 (Delivered), -3 (DeliverFailed)
	field :status, :type => Integer
	# field :status_desc, :type => String
	field :recipient, :type => String
	field :phone_number, :type => String

	embeds_one :cash_receive_info, :class_name => "CashReceiveInfo"
	embeds_one :realgoods_receive_info, :class_name => "RealgoodsReceiveInfo"
	embeds_one :virtualgoods_receive_info, :class_name => "VirtualgoodsReceiveInfo"
	embeds_one :lottery_receive_info, :class_name => "LotteryCodeReceiveInfo"

	has_one :point_log, :class_name => "PointLog"

	belongs_to :gift, :class_name => "BasicGift"
	belongs_to :user, :class_name => "User", :inverse_of => :orders
	belongs_to :operated_admin, :class_name => "User", :inverse_of => :operate_orders
	
	validates :type, :presence_ext => true,
									 :inclusion => { :in => 0..3 },
									 :numericality => true
	validates :status, :presence_ext => true,
									   :inclusion => { :in => -3..3 },
										 :numericality => true

	scope :for_cash, where( :type => 0)
	scope :for_realgoods, where( :type => 1)
	scope :for_virtualgoods, where( :type => 2)
	scope :for_lottery, where( :type => 3)

	scope :need_verify, where( :status => 0)
	scope :verified, where( :status => 1)
	scope :verify_failed, where( :status => -1)
	scope :delivering, where( :status => 2)
	scope :delivered, where( :status => 3)
	scope :deliver_failed, where( :status => -2)

	# TO DO validation verify
	# We must follow the Law of Demeter(summed up as "use only one dot"), and here is the code: 
	delegate :name, :to => :gift, :prefix => true
	#delegate :cash_order, :realgoods_order, :to => "self.need_verify", :prefix => true
	#after_create :decrease_point, :decrease_gift

	# TO DO I18n
	def operate(status)
		self.status = status
		self.save
	end

	private
	
	def decrease_point
		return if self.gift.blank? && self.user.blank?
		self.create_point_log(:order => self,
													:user => self.user,
													:operated_point => self.gift.point,
													:cause => 4)
	end

	def decrease_gift
		return if self.gift.blank?
		self.gift.inc(:surplus, -1)	
		self.save
	end

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

