# already tidied up
class Subscriber
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::ValidationsExt
  extend Mongoid::FindHelper
  include Mongoid::CriteriaExt

  field :email, type: String
  field :is_deleted, type: Boolean, default: false
  field :unsubscribed_at, type: Time

  has_and_belongs_to_many :newsletters

  # Validations
  default_scope order_by(:updated_at.desc)

  scope :subscribed, where(:is_deleted => false)
  scope :unsubscribed, where(:is_deleted => true)

  index({ email: 1 }, { background: true } )
  index({ is_deleted: 1 }, { background: true } )

  def present_admin
    present_attrs :_id, :email, :is_deleted
    present_add   :delivered_count => self.newsletters.count
    if self.unsubscribed_at
      present_add   :unsubscribed_at => self.unsubscribed_at.strftime("%Y-%m-%d")
    end
    present_add   :created_at => self.created_at.strftime("%Y-%m-%d")
  end

  def subscribe
    self.is_deleted = false
    save
  end

  def unsubscribe
    self.is_deleted = true
    self.unsubscribed_at = Time.now
    save
  end

end
