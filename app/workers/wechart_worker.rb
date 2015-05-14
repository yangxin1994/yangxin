class WechartWorker
  include Sidekiq::Worker
  sidekiq_options :retry => 10, :queue => "oopsdata_#{Rails.env}".to_sym

  def perform(type,opt={})
    case type
    when 'get_user_info'
      retval = Wechart.get_user_info(opt)
    end
    return true
  end
end
