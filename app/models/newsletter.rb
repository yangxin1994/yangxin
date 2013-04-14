class Newsletter
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::ValidationsExt
  extend Mongoid::FindHelper

  field :subject, type: String
  field :title, type: String
  field :status, type: Integer, default: 0
  field :content, type: Array, :default => []
  field :column, type: Array, :default => []
  field :is_deleted, type: Boolean, default: false

  has_and_belongs_to_many :subscribers

  default_scope where(:is_deleted => false)
  scope :editing, where(:status => 0)
  scope :delivering, where(:status => -1)
  scope :delivered, where(:status => 1)
  scope :canceled, where(:status => -2)

  def deliver_news
    Sidekiq.redis{|r| r.set('news_flag', '1')}
    NewsletterWorker.perform_async(self._id)
    self.status = -1
    save
    # Subscriber.all.each do |subscriber|
    #   NewsletterMailer.news_email(subscriber).deliver
    # end
  end

  def cancel
    self.status = -2
    self.save
    Sidekiq.redis{|r| r.set('news_flag', '0')}
  end
end
