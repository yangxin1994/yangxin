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
	# can be 1 (wait for deal), 2 (dealing), 4 (deal success), 8 (deal fail), 16 (cancel), 32 (frozen), 64 (reject)
	field :status, :type => Integer, :default => 1
	field :source, :type => Integer
	field :remark, :type => String, :default => "正常"
	field :amount, :type => Integer, :default => 0
	field :alipay_account, :type => String
	field :mobile, :type => String
	field :qq, :type => String
	field :receiver, :type => String
	field :address, :type => String
	field :street_info, :type => String
	field :postcode, :type => String
	field :express_info, :type => Hash
	field :reviewed_at, :type => Integer
	field :handled_at, :type => Integer
	field :finished_at, :type => Integer
	field :canceled_at, :type => Integer
	field :rejected_at, :type => Integer
	field :ofcard_order_id, :type => String, :default => ""
	field :point, :type => Integer, :default => 0

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
	REJECT = 64

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

	def self.create_redeem_order(sample_id, gift_id, amount, point, opt = {})
		sample = User.sample.find_by_id(sample_id)
		return ErrorEnum::SAMPLE_NOT_EXIST if sample.nil?
		gift = Gift.find_by_id(gift_id)
		return ErrorEnum::GIFT_NOT_EXIST if gift.nil?
		order = Order.create(:source => REDEEM_GIFT, :amount => amount, :point => point)
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
			order.receiver = opt["receiver"]
			order.mobile = opt["mobile"]
			order.address = opt["address"]
			order.street_info = opt["street_info"]
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
		order = Order.create(:source => ANSWER_SURVEY, :amount => amount, :type => type)
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
			ChargeClient.mobile_charge(self.mobile, self.amount, self._id.to_s)
		when JIFENBAO
		when QQ_COIN
			ChargeClient.qq_charge(self.qq, self.amount, self._id.to_s)
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

	def callback_confirm(ret_code, err_msg)
		self.remark = err_msg
		case ret_code.to_i
		when 1
			self.status = SUCCESS
			# send sample short message
			if self.type == MOBILE_CHARGE
				SmsApi.send_sms(self.mobile, "")
			end
		when 9
			self.status = FAIL
		end
		self.finished_at = Time.now.to_i
		return self.save
	end

	def self.wait_small_charge_orders
		orders = Order.where(:type => SMALL_MOBILE_CHARGE, :status => WAIT)
		max_number = 0
		amount = 0
		1.up_to(9) do |e|
			number = orders.where(:amount => e).length
			if number > max_number
				amount = e
				max_number = number
			end
		end
		orders = orders.where(:amount => e).limit(100)
		orders_for_ofcard = []
		orders.each do |o|
			o.status = HANDLE
			o.handled_at = Time.now.to_i
			o.save
			orders_for_ofcard << [o._id.to_s, o.mobile, e]
		end
		return orders_for_ofcard
	end

	def self.merge_order_id(orders)
		orders.each do |o|
			order = Order.find_by_id(o["orderid"])
			next if order.nil?
			order.ofcard_order_id = o["billid"]
			if o["stat"] == "成功"
				order.status = SUCCESS
				SmsApi.send_sms(order.mobile, "")
			elsif o["stat"] == "撤销"
				order.status = FAIL
			end
			order.save
		end
		return true
	end

	def self.handled_orders
		orders = Order.where(:type => SMALL_MOBILE_CHARGE, :status => HANDLE, :ofcard_order_id.ne => "").asc(:handled_at).limit(100)
		return orders.map { |e| e.ofcard_order_id }
	end

	def self.update_order_stat(orders)
		orders.each do |o|
			order = Order.find_by_ofcard_order_id(o["billid"])
			next if order.nil?
			if o["stat"] == "成功"
				order.status = SUCCESS
				SmsApi.send_sms(order.mobile, "")
			elsif o["stat"] == "撤销"
				order.status = FAIL
			end
		end
		return true
	end

	def info_for_sample
		order_obj = {}
		order_obj["_id"] = self._id.to_s
		order_obj["created_at"] = self.created_at.to_i
		order_obj["status"] = self.status
		order_obj["source"] = self.source
		order_obj["amount"] = self.amount
		if self.source == REDEEM_GIFT
			order_obj["point"] = self.point
			order_obj["title"] = self.gift.try(:title)
			order_obj["picture_url"] = self.gift.try(:photo).try(:picture_url)
		elsif self.source == WIN_IN_LOTTERY
			order_obj["title"] = self.prize.try(:title)
			order_obj["picture_url"] = self.prize.try(:photo).try(:picture_url)
		elsif self.source == ANSWER_SURVEY
			order_obj["type"] = self.type
		end
		return order_obj
	end

	def info_for_sample_detail
		self["created_at"] = self.created_at.to_i
		self["survey_title"] = self.survey.title if !self.survey.nil?
		self["survey_id"] = self.survey._id.to_s if !self.survey.nil?
		return self
	end
end
