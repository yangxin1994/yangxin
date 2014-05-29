class CarnivalChargeWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false, :queue => "oopsdata_#{Rails.env}".to_sym
  def perform(order_id, mobile, amount)
    retval = EsaiApi.new.charge_phone(mobile, amount, "None")
    order = CarnivalOrder.find(order_id)
    if retval.nil?
      order.esai_status = CarnivalOrder::ESAI_FAIL
    else
      order.esai_status = CarnivalOrder::ESAI_HANDLE
      order.esai_order_id = retval
    end
		r = order.save
  end
end
