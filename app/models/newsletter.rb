class Newsletter
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::ValidationsExt
  include FindTool
  include Mongoid::CriteriaExt

  field :subject, type: String
  field :title, type: String
  field :status, type: Integer, default: 0
  field :columns, type: Hash, default: {}
  field :is_tested, type: Boolean, default: false
  field :is_deleted, type: Boolean, default: false

  has_and_belongs_to_many :subscribers

  default_scope where(:is_deleted => false)
  scope :find_by_status, ->(_status) { _status.present? ? where(:status => _status) : self.all }

  index({ is_deleted: 1 }, { background: true } )
  index({ status: 1 }, { background: true } )

  def present_admin
    present_attrs :_id, :title, :subject, :status, :columns, :is_tested, :is_deleted
    present_add   :created_at=> self.created_at.strftime("%Y-%m-%d")
  end

  def deliver_news(content_html, protocol_hostname, callback)
    Sidekiq.redis{|r| r.set('news_flag', '1')}
    NewsletterWorker.perform_async(self._id, content_html, protocol_hostname, callback)
    self.status = -1
    save
    # Subscriber.all.each do |subscriber|
    #   NewsletterMailer.news_email(subscriber).deliver
    # end
  end

  def deliver_test_news(content_html, protocol_hostname, callback, test_emails)
    MailgunApi.newsletter(self, content_html, protocol_hostname, callback, test_emails)
    self.is_tested = true
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
