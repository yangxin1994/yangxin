class NewsletterWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false, :queue => "oopsdata_#{Rails.env}".to_sym

  def perform(newsletter)
    Subscriber.all.each do |sub|
      return unless $news_flag
      next if sub.newsletters.include? newsletter
      NewsletterMailer.news_email(newsletter, sub).deliver
      sub.newsletters << newsletter
      sub.save
    end
  end
end
