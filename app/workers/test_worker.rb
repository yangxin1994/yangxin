class TestWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false, :queue => "oopsdata_#{Rails.env}".to_sym

  def perform
    20.times do |e|
      puts e
      sleep(3)
    end
    return true
  end
end
