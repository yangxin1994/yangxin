class Newsletter
  include Mongoid::Document
  field :subject, type: String
  field :status, type: Integer, default: 1
  field :issue, type: Hash
  field :is_deleted, type: Boolean, default: false

  has_and_belongs_to_many :subscribers

  default_scope where(:is_deleted => false)

  def send_news
    $news_flag = true
    NewsletterWorker.perform_async(self)
    # Subscriber.all.each do |subscriber|
    #   NewsletterMailer.news_email(subscriber).deliver
    # end
  end

  def cancel
    @news_flag = false
  end
end
