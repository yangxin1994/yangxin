# encoding: utf-8

class Order
	include Mongoid::Document
	include Mongoid::Timestamps
	include Mongoid::ValidationsExt
	extend Mongoid::FindHelper
    include Mongoid::CriteriaExt

    field :code, :type => String, default: ->{ Time.now.strftime("%Y%m%d") + sprintf("%05d",rand(10000)) }
	# can be 1 (small mobile charge), 2 (large mobile charge), 4 (alipay), 8(alijf)
	# 16 (Q coins), 32 (prize), 64 (virtual prize)
	field :type, :type => Integer
	# can be 1 (wait for deal), 2 (dealing), 4 (deal success), 8 (deal fail), 16 (cancel), 32 (frozen)
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
	field :express_info, :type => Hash
	field :handled_at, :type => Integer
	field :finished_at, :type => Integer
	field :canceled_at, :type => Integer

	# embeds_one :cash_receive_info, :class_name => "CashReceiveInfo"
	# embeds_one :entity_receive_info, :class_name => "EntityReceiveInfo"
	# embeds_one :virtual_receive_info, :class_name => "VirtualReceiveInfo"
	# embeds_one :lottery_receive_info, :class_name => "LotteryReceiveInfo"

	belongs_to :prize
	belongs_to :survey
	belongs_to :gift
	belongs_to :answer
	belongs_to :sample, :class_name => "User", :inverse_of => :orders

	# status
	WAIT = 1
	HANDLE = 2
	SUCCESS = 4
	FAIL = 8
	CANCEL = 16
	FROZEN = 32

	# type
	SMALL_MOBILE_CHARGE = 1
	MOBILE_CHARGE = 2
	ALIPAY = 4
	JIFENBAO = 8
	QQ_COIN = 16
	REAL_GOOD = 32
	VIRTUAL_GOOD = 64

	# source
	ANSWER_SURVEY = 1
	WIN_IN_LOTTERY = 2
	REDEEM_GIFT = 4

	attr_accessible :mobile, :alipay_account, :qq, :user_name, :address, :postcode

	def self.find_by_id(order_id)
		return Order.where(:_id => order_id).first
	end

	def self.create_redeem_order(sample_id, gift_id, amount, opt = {})
		sample = User.sample.find_by_id(sample_id)
		return ErrorEnum::SAMPLE_NOT_EXIST if sample.nil?
		gift = Gift.find_by_id(gift_id)
		return ErrorEnum::GIFT_NOT_EXIST if gift.nil?
		order = Order.create(:source => REDEEM_GIFT, :amount => amount)
		order.sample = sample
		order.gift = gift
		case gift.type
		when Gift::MOBILE_CHARGE
			order.mobile = opt["mobile"]
		when Gift::ALIPAY
			order.alipay_account = opt["alipay_account"]
		when Gift::JIFENBAO
			order.alipay_account = opt["alipay_account"]
		when Gift::QQ_COIN
			order.qq = opt["qq"]
		when Gift::VIRTUAL
		when Gift::REAL
			order.user_name = opt["user_name"]
			order.address = opt["address"]
			order.postcode = opt["postcode"]
		end
		order.save
		order.auto_handle
		return order
	end

	def self.create_lottery_order(sample_id, survey_id, prize_id, opt = {})
		sample = User.sample.find_by_id(sample_id)
		return ErrorEnum::SAMPLE_NOT_EXIST if sample.nil?
		survey = Survey.find_by_id(survey_id)
		return ErrorEnum::SURVEY_NOT_EXIST if survey.nil?
		prize = Prize.find_by_id(prize_id)
		return ErrorEnum::PRIZE_NOT_EXIST if prize.nl?
		order = Order.new(:source => WIN_IN_LOTTERY)
		order.sample = sample
		order.survey = survey
		order.prize = prize
		case prize.type
		when Prize::MOBILE_CHARGE
			order.mobile = opt["mobile"]
		when Prize::ALIPAY
			order.alipay_account = opt["alipay_account"]
		when Prize::JIFENBAO
			order.alipay_account = opt["alipay_account"]
		when Prize::QQ_COIN
			order.qq = opt["qq"]
		when Prize::VIRTUAL
		when Prize::REAL
			order.user_name = opt["user_name"]
			order.address = opt["address"]
			order.postcode = opt["postcode"]
		end
		order.status = FROZEN if opt["status"] == FROZEN
		order.save
		order.auto_handle
		return order
	end

	def self.create_answer_order(sample_id, survey_id, type, amount, opt = {})
		sample = User.sample.find_by_id(sample_id)
		return ErrorEnum::SAMPLE_NOT_EXIST if sample.nil?
		survey = Survey.find_by_id(survey_id)
		return ErrorEnum::SURVEY_NOT_EXIST if survey.nil?
		order = Order.create(:source => ANSWER_SURVEY, :amount => amount)
		order.sample = sample
		order.survey = survey
		case type
		when SMALL_MOBILE_CHARGE
			order.mobile = opt["mobile"]
		when ALIPAY
			order.alipay_account = opt["alipay_account"]
		when JIFENBAO
			order.alipay_account = opt["alipay_account"]
		end
		order.save
		order.auto_handle
		return order
	end

	def update_order(order)
		return self.update_attributes(order)
	end

	def auto_handle
		return false if self.status != WAIT
		return false if ![MOBILE_CHARGE, JIFENBAO, QQ_COIN].include?(self.type)
		case self.type
		when MOBILE_CHARGE
		when JIFENBAO
		when QQ_COIN
		end
	end

	def manu_handle
		return ErrorEnum::WRONG_ORDER_STATUS if self.status != WAIT
		self.status = HANDLE
		self.handled_at = Time.now.to_i
		return self.save
	end

	def cancel
		return ErrorEnum::WRONG_ORDER_STATUS if self.status != WAIT
		self.status = wait
		self.canceled_at = Time.now.to_i
		return self.save
	end

	def finish(success, remark = "")
		return ErrorEnum::WRONG_ORDER_STATUS if self.status != HANDLE
		self.status = success ? SUCCESS : FAIL
		self.remark = remark
		self.finished_at = Time.now.to_i
		return self.save
	end

	def self.search_orders(email, mobile, code, status, source, type)
		if !email.blank?
			orders = User.sample.find_by_email(email).try(:orders) || []
		elsif !mobile.blank?
			orders = User.sample.find_by_mobile(mobile).try(:orders) || []
		elsif !code.blank?
			orders = Order.where(:code => /#{code}/)
		else
			orders = Order.all
		end

		if !status.blank? && status != 0
			status_ary = Tool.convert_int_to_base_arr(status)
			orders = orders.where(:status.in => status_ary)
		end
		if !source.blank? && source != 0
			source_ary = Tool.convert_int_to_base_arr(source)
			orders = orders.where(:source.in => source_ary)
		end
		if !type.blank? && type != 0
			type_ary = Tool.convert_int_to_base_arr(type)
			orders = orders.where(:type.in => type_ary)
		end
		return orders
	end

	def update_express_info(express_info)
		self.express_info = express_info
		return self.save
	end

	def update_remark(remark)
		self.remark = remark
		return self.save
	end
end