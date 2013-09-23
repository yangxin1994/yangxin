class RemoveBouncedEmailWorker
    include Sidekiq::Worker
    sidekiq_options :retry => false, :queue => "oopsdata_#{Rails.env}".to_sym
    def perform
        ImportEmail.remove_bounce_emails
        return true
    end
end
