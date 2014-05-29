# encoding: utf-8
class CarnivalOrder
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::ValidationsExt
  include Mongoid::CriteriaExt
  include FindTool

  # status
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
  field :amount, :type => Integer
  field :mobile, :type => String
  field :reviewed_at, :type => Integer
  field :handled_at, :type => Integer
  field :finished_at, :type => Integer
  field :rejected_at, :type => Integer
  field :esai_order_id, :type => String, :default => ""
  # 3 for handling, 4 for success, 5 for fail
  field :esai_status, :type => Integer

  belongs_to :carnival_user
  belongs_to :carnival_prize

  index({ code: 1 }, { background: true } )
  index({ status: 1 }, { background: true } )
  index({ source: 1 }, { background: true } )
  index({ amount: 1 }, { background: true } )
  index({ type: 1, status: 1, esai_order_id: 1}, { background: true } )

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
end
