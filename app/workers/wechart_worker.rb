class WechartWorker
  include Sidekiq::Worker
  sidekiq_options :retry => 10, :queue => "oopsdata_#{Rails.env}".to_sym

  def perform(type,opt={})
    case type
    when 'create'
      puts "**************openid:#{opt.inspect}*************"
      retval = WechartUser.add_new_user(opt)
    end
    return true
  end
end
