# encoding: utf-8

class Order
	include Mongoid::Document
	include Mongoid::Timestamps
	include Mongoid::ValidationsExt
	extend Mongoid::FindHelper
    include Mongoid::CriteriaExt

    field :code, :type => String, :default => "unkonwn"
	# can be 1 (small mobile charge), 2 (large mobile charge), 4 (alipay), 8(alijf)
	# 16 (Q coins), 32 (prize), 64 (virtual prize)
	field :type, :type => Integer
	# can be 1 (wait for deal), 2 (dealing), 4 (deal success), 8 (deal fail), 16 (cancel)
	field :status, :type => Integer, :default => 1
	field :source, :type => Integer
	field :remark, :type => String, :default => "正常"
	field :amount, :type => Integer, :default => 0
	field :alipay_account, :type => String
	field :mobile, :type => String
	field :qq, :type => String
	field :user_name, :type => String
	field :address, :type => String
	field :postcode, :type => String

	# embeds_one :cash_receive_info, :class_name => "CashReceiveInfo"
	# embeds_one :entity_receive_info, :class_name => "EntityReceiveInfo"
	# embeds_one :virtual_receive_info, :class_name => "VirtualReceiveInfo"
	# embeds_one :lottery_receive_info, :class_name => "LotteryReceiveInfo"

	belongs_to :prize
	belongs_to :survey
	belongs_to :gift
	belongs_to :sample, :class_name => "User", :inverse_of => :orders
	belongs_to :operator, :class_name => "User", :inverse_of => :operate_orders
=begin
	validates :type, :presence_ext => true,
		:inclusion => { :in => [1, 2, 4, 8, 16, 32, 64] },
		:numericality => true
	validates :status, :presence_ext => true,
		:inclusion => { :in => [1, 2, 4, 8, 16] },
		:numericality => true

	# default_scope where(:is_deleted => false).order_by(:created_at.desc)

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
=end
	def self.find_by_id(order_id)
		return Order.where(:_id => order_id).first
	end

	def self.create_order(params)
		order_type = {
			1 => "mobile",  ## small_mobile_charge
			2 => "mobile",  ## large_mobile_charge
			4 => "alipay_account",
			8 => "alipay_account",  ## alijf
			16 => "qq",
			32 => "prize",
			64 => "virtual_prize"
		}
		return ErrorEnum::ORDER_TYPE_ERROR if !order_type.keys.include?(params[:type])
		new_order = Order.create({"code" => code_generater, "type" => params[:type], "source" => params[:source]})
		User.where("_id" => params[:user_id]).first.orders << new_order
		if params(:type) < 32
			new_order.send "create_charge_order(params, order_type)"
		else
			new_order.send "create_#{order[params[:type]]}_order(params)"
		end
	end

	def create_charge_order(params, order_type)
		self.update_attributes({"amount" => params[:amount],
			order_type[params[:type]] => params[order_type[params[:type]].to_sym]})
		return true
	end

	def create_prize_order(params)
		self.update_attributes({"address" => params[:address],
			"postcode" => params[:postcode]},
			"user_name" => params[:user_name],
			"mobile" => params[:mobile]
			)
		Prize.where("_id" => params[:prize_id]).first.orders << self
		return true
	end

	def create_virtual_prize_order(params)
		Prize.where("_id" => params[:prize_id]).first.orders << self
	end

	def update_order_status(status, remark)
		status_message = {"status" => status}
		status_message["remark"] = remark if status == 8 and !remark.blank?
		self.update_attributes(status_message)
		return true
	end

	def self.search_orders(params)
		select_fileds = {}
		[:type, :code, :status, :source].each do |field|
			select_fileds[field] = params[field.to_sym] if !params[field.to_sym].blank?
		end
		order_list = (select_fileds.blank? ? Order.all : Order.where(select_fileds))

		[:email, :mobile].each do |user_field|
			 if !params[user_field].blank? and !order_list[0].blank?
			 	order_list = order_list.delete_if { |order|
			 		order.sample.send(user_field) != params[user_field] }
			 end
		end
		return order_list
	end

	def self.code_generater
		rand_code = Time.now.strftime("%Y%m%d") + sprintf("%05d",rand(10000))
		return rand_code
	end

	##---------------------------------------TODO:be deleted-------------------------------------------------------
=begin
	def self.to_excel(scope)
		# csv= []
		# csv << ["奖品名称", "时间", "用户名", "电话号码", "地址", "邮编", "电子邮箱", "姓名", "证件号", "开户行", "银行卡号", "支付宝"].join(',')
		# Order.all.page(1).per(300).send(scope).map do |order|
		# 	csv << [order.gift.name,
		# 	  			order.created_at.strftime('%F %R'),
		# 					order.user.username, order.phone,
		# 					order.address,
		# 					order.postcode,
		# 					order.email,
		# 					order.bank,
		# 		   		order.bankcard_number,
		# 					order.alipay_account].join(',')
		# end
		path = "public/import/order.csv"
		c = CSV.open(path, "w") do |csv|
			csv << ["奖品名称", "时间", "用户名", "电话号码", "地址", "邮编", "电子邮箱", "姓名", "证件号", "开户行", "银行卡号", "支付宝"]
			Order.all.page(1).per(300).send(scope).map do |order|
				csv << [order.gift.name,
								order.created_at.strftime('%F %R'),
								order.user.username, order.phone,
								order.address,
								order.postcode,
								order.email,
								order.bank,
								order.bankcard_number,
								order.alipay_account]
			end
		end
		csv = File.read("public/import/order.csv")
	end

	def present_quillme
    present_attrs :_id, :type, :status, :is_prize
    present_add :gift => self.gift.present_attrs
	end

	def present_admin
    present_attrs :_id, :type, :status, :is_prize, :gift, :created_at, :is_update_user,
    	:full_name, :identity_card, :bank, :bankcard_number, :alipay_account,
    	:phone, :address, :postcode, :email
    present_add :email => self.user.email
    present_add :user_id => self.user._id
    present_add :gift_name => self.gift_name
    present_add :gift_id => self.gift._id
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
=end
end
