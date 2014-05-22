# encoding: utf-8
class Order
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::ValidationsExt
  include Mongoid::CriteriaExt
  include FindTool

  # status
  WAIT = 1
  HANDLE = 2
  SUCCESS = 4
  FAIL = 8
  CANCEL = 16
  FROZEN = 32
  REJECT = 64

  # esai status
  ESAI_HANDLE = 3
  ESAI_SUCCESS = 4
  ESAI_FAIL = 5

  # type
  VIRTUAL = 1
  REAL = 2
  MOBILE_CHARGE = 4
  ALIPAY = 8
  JIFENBAO = 16
  QQ_COIN = 32
  SMALL_MOBILE_CHARGE = 64

  # source
  ANSWER_SURVEY = 1
  WIN_IN_LOTTERY = 2
  REDEEM_GIFT = 4


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
  field :esai_order_id, :type => String, :default => ""
  # 3 for handling, 4 for success, 5 for fail
  field :esai_status, :type => Integer
  field :point, :type => Integer, :default => 0

  belongs_to :prize
  belongs_to :survey
  belongs_to :gift
  belongs_to :answer
  belongs_to :sample, :class_name => "User", :inverse_of => :orders

  index({ code: 1 }, { background: true } )
  index({ status: 1 }, { background: true } )
  index({ source: 1 }, { background: true } )
  index({ amount: 1 }, { background: true } )
  index({ type: 1, status: 1, esai_order_id: 1}, { background: true } )

  #attr_accessible :mobile, :alipay_account, :qq, :sample_name, :address, :postcode

  def self.create_redeem_order(sample_id, gift_id, amount, point, opt = {})
    gift  = Gift.normal.find_by_id(gift_id)
    return ErrorEnum::ORDER_ERROR if amount.to_i < 1
    point = gift.point.to_i  * amount.to_i
    sample = User.sample.find_by_id(sample_id)
    return ErrorEnum::POINT_NOT_ENOUGH if sample.point.to_i < point.to_i 
    return ErrorEnum::SAMPLE_NOT_EXIST if sample.nil?
    gift = Gift.normal.find_by_id(gift_id)
    return ErrorEnum::GIFT_NOT_EXIST if gift.nil?
    order = Order.create(:source => REDEEM_GIFT, :amount => amount, :point => point, :type => gift.type)
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
    sample.point -= point 
    sample.save
    PointLog.create_redeem_point_log(point,gift_id,sample_id)
    RedeemLog.create_gift_exchange_logs(amount,point,gift.type,order.id,gift_id,sample_id)
    order.auto_handle
    return order
  end

  def self.create_lottery_order(answer_id, sample_id, survey_id, prize_id, ip_address, opt = {})
    sample = User.sample.find_by_id(sample_id)
    survey = Survey.find_by_id(survey_id)
    return ErrorEnum::SURVEY_NOT_EXIST if survey.nil?
    prize = Prize.normal.find_by_id(prize_id)
    return ErrorEnum::PRIZE_NOT_EXIST if prize.nil?
    order = Order.new(:source => WIN_IN_LOTTERY, :type => prize.type, :amount => prize.amount)
    order.sample = sample if sample.present?
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
      order.receiver = opt["receiver"]
      order.address = opt["address"]
      order.postcode = opt["postcode"]
      order.mobile = opt["mobile"]
      order.street_info = opt["street_info"]
    end
    order.status = FROZEN if opt["status"] == FROZEN
    order.save
    order.auto_handle

    ##synchro  reverver info 
    if opt['info_sys'].to_s == 'true'
      option = {}
      option["receiver"]    = order[:receiver] 
      option["mobile"]      = order[:mobile]
      option["address"]     = order[:address]
      option["street_info"] = order[:street_info]
      option["postcode"]    = order[:postcode]
      sample.set_receiver_info(option) if sample.present?
    end 

    LotteryLog.create_succ_lottery_Log(answer_id:answer_id,
                      order_id:order.id,
                      survey_id:survey_id,
                      sample_id:sample_id,
                      ip_address:ip_address,
                      prize_id:prize_id
                      )
    return order
  end

  def self.create_answer_alipay_order(answer, reward)
    order_info = { "alipay_account" => reward["alipay_account"] }
    order_info.merge!("status" => FROZEN) if answer.status == Answer::UNDER_REVIEW
    Order.create_answer_order(
      answer.id.to_s,
      answer.user.try(:_id),
      answer.survey._id.to_s,
      ALIPAY,
      reward["amount"],
      order_info)
  end

  def self.create_answer_jifenbao_order(answer, reward)
    order_info = { "alipay_account" => reward["alipay_account"] }
    order_info.merge!("status" => FROZEN) if answer.status == Answer::UNDER_REVIEW
    Order.create_answer_order(
      answer.id.to_s,
      answer.user.try(:_id),
      answer.survey._id.to_s,
      JIFENBAO,
      reward["amount"],
      order_info)
  end

  def self.create_answer_mobile_order(answer, reward)
    order_info = { "mobile" => reward["mobile"] }
    order_info.merge!("status" => FROZEN) if answer.status == Answer::UNDER_REVIEW
    Order.create_answer_order(
      answer.id.to_s,
      answer.user.try(:_id),
      answer.survey._id.to_s,
      SMALL_MOBILE_CHARGE,
      reward["amount"],
      order_info)
  end


  def self.create_answer_order(answer_id, sample_id, survey_id, type, amount, opt = {})
    sample = User.sample.find_by_id(sample_id)
    survey = Survey.find_by_id(survey_id)
    answer = Answer.find(answer_id)
    return ErrorEnum::SURVEY_NOT_EXIST if survey.nil?
    order = Order.create(:source => ANSWER_SURVEY, :amount => amount, :type => type)
    order.sample = sample if sample.present?
    order.survey = survey
    order.answer = answer
    case type
    when SMALL_MOBILE_CHARGE
      order.mobile = opt["mobile"]
    when ALIPAY
      order.alipay_account = opt["alipay_account"]
    when JIFENBAO
      order.alipay_account = opt["alipay_account"]
    end
    order.status = opt["status"] if opt["status"].present?
    order.save
    order.auto_handle
    return order
  end

  def auto_handle
    return false if self.status != WAIT
    return false if self.type != MOBILE_CHARGE
    # retval = EsaiApi.new.charge_phone(self.mobile, self.amount, "None")
    self.status = HANDLE
    self.esai_status = ESAI_HANDLE
    self.handled_at = Time.now
    self.save
    ChargeWorker.perform_async(self.id.to_s, self.mobile, self.amount)
=begin
    if retval.nil?
      self.esai_status = ESAI_FAIL
    else
      self.esai_status = ESAI_HANDLE
      self.esai_order_id = retval
    end
=end
  end

  def self.recharge_fail_mobile
    Order.where(esai_status: ESAI_FAIL, status: HANDLE, type: MOBILE_CHARGE).each do |order|
      order.update_attributes(status: WAIT)
      order.auto_handle
    end
  end

  def check_result
    return nil if self.esai_order_id.blank?
    retval = EsaiApi.new.check_result(self.esai_order_id, "None")
    case retval
    when 0, 1, 2
      self.update_attributes({status: HANDLE, esai_status: ESAI_HANDLE})
    when 4
      self.update_attributes({status: SUCCESS, esai_status: ESAI_SUCCESS})
      self.send_mobile_charge_success_message
    when 5
      self.update_attributes({status: HANDLE, esai_status: ESAI_FAIL})
    end
    return self.esai_status
  end

  def send_mobile_charge_success_message
    SmsWorker.perform_async("charge_notification", self.mobile, "", gift_name: "#{self.amount}元话费")
  end

  def manu_handle
    return ErrorEnum::WRONG_ORDER_STATUS if self.status != WAIT
    self.status = HANDLE
    self.handled_at = Time.now.to_i
    return self.save
  end

  def finish(success, remark = "")
    return ErrorEnum::WRONG_ORDER_STATUS if self.status != HANDLE
    self.status = success ? SUCCESS : FAIL
    self.remark = remark
    self.finished_at = Time.now.to_i
    if self.status == FAIL && self.source == REDEEM_GIFT
      sample = self.sample
      sample.point = sample.point + point
      sample.save
      PointLog.create_admin_operate_point_log(point, "兑换失败，积分返还", sample._id.to_s)
    end
    return self.save
  end

  def self.search_orders(options = {})
    options[:status] = options[:status].to_i
    options[:source] = options[:source].to_i
    options[:type] = options[:type].to_i
    options.delete(:type) if options[:type] == 0
    if options[:email].present?
      orders = User.find_by_email(options[:email]).try(:orders)
      orders = orders.nil? ? [] : orders.desc(:created_at)
    elsif options[:mobile].present?
      orders = User.find_by_mobile(options[:mobile]).try(:orders)
      orders = orders.nil? ? [] : orders.desc(:created_at)
    elsif options[:code].present?
      orders = Order.where(:code => /#{options[:code]}/).desc(:created_at)
    else
      orders = Order.all.desc(:created_at)
    end
    if options[:status].present? && options[:status] != 0
      status_ary = Tool.convert_int_to_base_arr(options[:status])
      orders = orders.where(:status.in => status_ary)
    end
    if options[:source].present? && options[:source] != 0
      source_ary = Tool.convert_int_to_base_arr(options[:source])
      orders = orders.where(:source.in => source_ary)
    end
    if options[:type].present? && options[:type] != 0
      type_ary = Tool.convert_int_to_base_arr(options[:type])
      orders = orders.where(:type.in => type_ary)
    end 
    if options[:date_max].present?
      orders = orders.where(:created_at.lt => Time.parse(options[:date_max]))
    elsif options[:date_min].present?
      orders = orders.where(:created_at.gt => Time.parse(options[:date_min]))
    else
      if options[:date].present?
        _qdate = Time.now - options[:date].to_i.days
        orders = orders.where(:created_at.gt => _qdate)
      end
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

  def info_for_admin
    if self.source == REDEEM_GIFT
      self.write_attribute(:gift_name, self.gift.try(:title))
    elsif self.source == WIN_IN_LOTTERY
      self.write_attribute(:prize_name, self.prize.try(:title))
    end
    self.write_attribute(:gift_id, (self.gift || self.prize).try(:_id))
    self.write_attribute(:user_email_mobile, self.sample.try(:email) || self.sample.try(:mobile))
    self.write_attribute(:user_id, self.sample.try(:id))
    if self.type == 2
      self.write_attribute(:address_str, address_str)
    end
    return self
  end

  def update_status(handle = true)
    self.update_attributes({"status" => Order::WAIT, "reviewed_at" => Time.now.to_i}) if self.answer.is_finish
    self.update_attributes({"status" => Order::REJECT, "reviewed_at" => Time.now.to_i} ) if self.answer.is_reject
    self.auto_handle if handle
  end

  def info_for_sample
    order_obj = {}
    order_obj["_id"] = self._id.to_s
    order_obj["created_at"] = self.created_at.to_i
    order_obj["status"] = self.status
    order_obj["source"] = self.source
    order_obj["amount"] = self.amount
    order_obj["type"] = self.type
    if self.source == REDEEM_GIFT
      order_obj["point"] = self.point
      order_obj["title"] = self.gift.try(:title)
      order_obj["picture_url"] = self.gift.try(:photo).try(:picture_url)
      order_obj["gift_id"] = self.gift.try(:_id)
    elsif self.source == WIN_IN_LOTTERY
      order_obj["title"] = self.prize.try(:title)
      order_obj["picture_url"] = self.prize.try(:photo).try(:picture_url)
    end
    return order_obj
  end


  def info_for_sample_detail
    order_obj = JSON.parse(self.to_json)
    order_obj["created_at"] = self.created_at.to_i
    order_obj["survey_title"] = self.survey.title if !self.survey.nil?
    order_obj["survey_id"] = self.survey._id.to_s if !self.survey.nil?
    return order_obj
  end

  def address_str
    QuillCommon::AddressUtility.find_province_city_town_by_code(self.address) + " " +
      self.street_info.to_s + " " + self.postcode.to_s + " " + self.receiver.to_s    
  end

  def self.to_excel
    self.criteria.map do |order|
      item = order.gift || order.prize
      sample = order.sample
      unless sample && item
        next
      end
      case order.type
      when 1
        "#{sample.email || sample.mobile},#{item.title}-#{order.amount},支付宝账号:#{order.alipay_account}"
      when 2
        "#{sample.email || sample.mobile},#{item.title}-#{order.amount},地址:#{order.address_str} 邮编:#{order.postcode} 收件人:#{order.receiver} 电话:#{order.mobile}"
      when 4
        "#{sample.email || sample.mobile},#{item.title}-#{order.amount},电话:#{order.mobile || order.sample.mobile}"
      when 8
        "#{sample.email || sample.mobile},#{item.title}-#{order.amount},支付宝账号:#{order.alipay_account}"
      when 16
        "#{sample.email || sample.mobile},#{item.title}-#{order.amount},集分宝账号:#{order.alipay_account}"
      when 32
        "#{sample.email || sample.mobile},#{item.title}-#{order.amount},QQ:#{order.qq}"
      when 64
        "#{sample.email || sample.mobile},#{item.title}-#{order.amount},电话:#{order.mobile || order.sample.mobile}"
      end
    end.join("\n")
  end
end

