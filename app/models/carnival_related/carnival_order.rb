# encoding: utf-8
class CarnivalOrder
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
  REJECT = 64
  UNDER_REVIEW = 128

  # esai status
  ESAI_HANDLE = 3
  ESAI_SUCCESS = 4
  ESAI_FAIL = 5

  # type
  # 0代表第二个大任务的抽奖，1代表第三个大任务的抽奖，2代表分享成功的抽奖，3代表第一个大任务的10元充值卡，4代表第三个大任务的10充值卡
  STAGE_2 = 0
  STAGE_3_LOTTERY = 1
  SHARE = 2
  STAGE_1 = 3
  STAGE_3 = 4


  field :code, type: String, default: ->{ Time.now.strftime("%Y%m%d") + sprintf("%05d",rand(10000)) }
  field :status, type: Integer
  field :type, :type => Integer
  field :remark, :type => String
  field :amount, :type => Integer
  field :mobile, :type => String
  field :reviewed_at, :type => Integer
  field :handled_at, :type => Integer
  field :finished_at, :type => Integer
  field :rejected_at, :type => Integer
  field :esai_order_id, :type => String, :default => ""
  field :express_info, :type => Hash
  # 3 for handling, 4 for success, 5 for fail
  field :esai_status, :type => Integer

  belongs_to :carnival_user
  belongs_to :carnival_prize

  index({ code: 1 }, { background: true } )
  index({ status: 1 }, { background: true } )
  index({ amount: 1 }, { background: true } )
  index({ type: 1, status: 1, esai_order_id: 1}, { background: true } )

  def self.search_orders(options = {})
    options[:status] = options[:status].to_i
    options[:type] = options[:type].to_i
    options.delete(:type) if options[:type] == 0
    if options[:mobile].present?
      orders = CarnivalUser.find_by_mobile(options[:mobile]).try(:carnival_orders)
      if orders
        orders = orders.desc(:created_at)
      else
        return []
      end
    elsif options[:code].present?
      orders = CarnivalOrder.where(:code => /#{options[:code]}/).desc(:created_at)
    else
      orders = CarnivalOrder.all.desc(:created_at)
    end
    if options[:status].present? && options[:status] != 0
      status_ary = Tool.convert_int_to_base_arr(options[:status])
      orders = orders.where(:status.in => status_ary)
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

  def handle
    return if self.status != WAIT
    return if [STAGE_1, STAGE_2, STAGE_3].include?(self.type)

    # only hanlde the mobile orders that are in wait status
    self.status = HANDLE
    self.esai_status = ESAI_HANDLE
    self.handled_at = Time.now
    self.save
    CarnivalChargeWorker.perform_async(self.id.to_s, self.mobile, self.amount)
  end

  def manu_handle
    return ErrorEnum::WRONG_ORDER_STATUS if self.status != WAIT
    self.status = HANDLE
    self.handled_at = Time.now.to_i
    return self.save
  end  

  def under_review
    if self.status == REJECT
      self.update_attributes(status: UNDER_REVIEW)
    end
  end

  def reject
    if self.status == UNDER_REVIEW
      self.update_attributes(status: REJECT)
    end
  end

  def pass
    if self.status == UNDER_REVIEW
      self.update_attributes(status: WAIT)
      self.hanlde
    end
  end

  def finish(success, remark = "")
    return ErrorEnum::WRONG_ORDER_STATUS if self.status != HANDLE
    self.status = success ? SUCCESS : FAIL
    self.remark = remark
    self.finished_at = Time.now.to_i
    return self.save
  end

  def express_str
    str = ""
    if type == 1
      str = "易赛订单号: #{esai_order_id}"
    else
      str = "快递公司: #{express_info["company"]}
      单号:#{express_info["tracking_number"]}
      发货时间: #{express_info["sent_at"]}"
    end
  end

  def update_express_info(express_info)
    self.express_info = express_info
    return self.save
  end

  def update_remark(remark)
    self.remark = remark
    return self.save
  end

  def update_status(handle = true)
    self.update_attributes({"status" => CarnivalOrder::WAIT, "reviewed_at" => Time.now.to_i}) if self.answer.is_finish
    self.update_attributes({"status" => CarnivalOrder::REJECT, "reviewed_at" => Time.now.to_i} ) if self.answer.is_reject
    self.auto_handle if handle
  end

end
