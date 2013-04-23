class Order
	include Mongoid::Document
	include Mongoid::Timestamps
	include Mongoid::ValidationsExt
	extend Mongoid::FindHelper
  include Mongoid::CriteriaExt
	# can be 0 (Cash), 1 (Entity), 2 (Virtual), 3 (Lottery)
	field :type, :type => Integer
	# can be 0 (NeedVerify), 1 (Verified), -1 (VerifyFailed), 2 (Delivering), 3 (Delivered), -3 (DeliverFailed)
	field :is_prize, :type => Boolean, :default => false
	field :status, :type => Integer, :default => 0
	field :status_desc, :type => String
	field :is_deleted, :type => Boolean, :default => false

	field :is_update_user, :type => Boolean, :default => false
	field :full_name, :type => String
	field :identity_card, :type => String
	field :bank, :type => String
	field :bankcard_number, :type => String
	field :alipay_account, :type => String
	field :phone, :type => String
	field :address, :type => String
	field :postcode, :type => String
	field :email, :type => String

	# embeds_one :cash_receive_info, :class_name => "CashReceiveInfo"
	# embeds_one :entity_receive_info, :class_name => "EntityReceiveInfo"
	# embeds_one :virtual_receive_info, :class_name => "VirtualReceiveInfo"
	# embeds_one :lottery_receive_info, :class_name => "LotteryReceiveInfo"

	has_one :reward_log, :class_name => "RewardLog"
	belongs_to :lottery_code, :class_name => "LotteryCode"
	belongs_to :gift, :class_name => "BasicGift", :inverse_of => :order
	belongs_to :user, :class_name => "User", :inverse_of => :orders
	belongs_to :operator, :class_name => "User", :inverse_of => :operate_orders

	validates :type, :presence_ext => true,
		:inclusion => { :in => 0..3 },
		:numericality => true
	validates :status, :presence_ext => true,
		:inclusion => { :in => -3..3 },
		:numericality => true

	default_scope where(:is_deleted => false).order_by(:created_at.desc)

	scope :for_cash, where( :type => 0)
	scope :for_entity, where( :type => 1)
	scope :for_virtual, where( :type => 2)
	scope :for_lottery, where( :type => 3)

	scope :need_verify, where( :status => 0).order_by(:created_at.asc)
	scope :verified, where( :status => 1)
	scope :verify_failed, where( :status => -1)
	scope :canceled, where( :status => -2)
	scope :delivering, where( :status => 2)
	scope :delivered, where( :status => 3)
	scope :deliver_failed, where( :status => -3)

	# TO DO validation verify
	# We must follow the Law of Demeter(summed up as "use only one dot"), and here is the code:
	delegate :name, :to => :gift, :prefix => true
	delegate :create, :to => :reward_log, :prefix => true
	#delegate :cash_order, :realgoods_order, :to => "self.need_verify", :prefix => true
	#after_create :decrease_point, :decrease_gift


	def present_quillme
    present_attrs :_id, :type, :status, :is_prize
    present_add :gift => self.gift.present_attrs
	end

	def present_admin
    present_attrs :_id, :type, :status, :is_prize, :gift, :created_at, :is_update_user,
    	:full_name, :identity_card, :bank, :bankcard_number, :alipay_account,
    	:phone, :address, :postcode, :email
    present_add :gift_name => self.gift_name
    present_add :gift => self.gift.present_attrs

	end

	index({ is_deleted: 1 }, { background: true } )
	index({ type: 1 }, { background: true } )
	index({ status: 1 }, { background: true } )

	def as_retval
		return @ret_error if @ret_error
		super
	end
	def prize
		self.gift
	end
	# TO DO I18n
	#after_create :decrease_gift, :update_user_info
	after_create :exchange
	private
	def exchange
		if !(is_prize ? ex_prize : ex_gift)
			self.is_deleted = true
			self.delete
		end
	end

	def ex_gift
		decrease_point && decrease_gift && update_user_info
	end

	def ex_prize
		ck_lottery_code && decrease_prize && update_user_info
	end

	def decrease_point
		# p self
		if self.gift.blank? || self.user.blank? || self.gift.point > self.user.point
			@ret_error= {
				:error_code => ErrorEnum::POINT_NOT_ENOUGH,
				:error_message => "point not enough"
			}
			return false
		end
		self.create_reward_log(:type => 2,
													 :user => self.user,
													 :point => -self.gift.point,
													 :cause => 4)
		self.save
	end

	def decrease_gift
		if self.gift.blank? || self.gift.surplus <= 0 || self.gift.is_deleted
			@ret_error= {
				:error_code => ErrorEnum::GIFT_NOT_ENOUGH,
				:error_message => "gift not enough"
			}
			return false
		end
		# if self.gift.type == 3
		#   self.gift.lottery.give_lottery_code_to(self.user)
		# end
		self.gift.inc(:surplus, -1)
		self.save
	end

	def ck_lottery_code
		if self.lottery_code.blank? || self.lottery_code.status != 2
			@ret_error= {
				:error_code => ErrorEnum::INVALID_LOTTERYCODE_ID,
				:error_message => "Invalid lottery code"
			}
			return false
		end
		self.lottery_code.status = 4
		self.lottery_code.save
	end

	def decrease_prize

		if self.prize.blank? || self.prize.surplus < 0
			@ret_error= {
				:error_code => ErrorEnum::PRIZE_NOT_ENOUGH,
				:error_message => "prize not enough"
			}
			return false
		end
		# if self.prize.type == 3
		#   self.prize.lottery.give_lottery_code_to(self.user)
		# end
		# self.prize.inc(:surplus, -1)
		self.save
	end
	# def decrease_gift
	#   return false if self.gift.blank? || self.user.blank? || self.gift.point > self.user.point
	#   self.create_reward_log(:order => self,
	#                          :type => 1,
	#                          :user => self.user,
	#                          :point => -self.gift.point,
	#                          :cause => 4)
	#   if self.gift.type == 3
	#     self.gift.lottery.give_lottery_code_to(self.user)
	#   end
	#   self.gift.inc(:surplus, -1)
	#   self.save
	# end

	def update_user_info
		return false if self.user.blank?
		return true unless self.is_update_user
		case self.type
		when 0
			self.user.update_attributes({
																		:full_name => self.full_name,
																		:identity_card => self.identity_card,
																		:bank => self.bank,
																		:bankcard_number => self.bankcard_number,
																		:alipay_account => self.alipay_account,
																		:phone => self.phone},
																		:without_protection => true)
		when 1
			self.user.update_attributes({
																		:full_name => self.full_name,
																		:address => self.address,
																		:postcode => self.postcode,
																	:phone => self.phone},
																	:without_protection => true)
		when 2
			self.user.update_attributes({
																		:full_name => self.full_name,
																	:phone => self.phone},
																	:without_protection => true)
		when 3

		end
		#self.user.update_attributes(self.attributes, :without_protection => true)
	end
end
