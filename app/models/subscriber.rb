# already tidied up
class Subscriber
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::ValidationsExt
  extend Mongoid::FindHelper
  include Mongoid::CriteriaExt

  field :email, type: String
  field :subscribed, type: Boolean, default: false
  field :is_deleted, type: Boolean, default: false
  field :unsubscribed_at, type: Time

  has_and_belongs_to_many :newsletters

  # Validations
  default_scope desc(:created_at)

  scope :subscribed, where(:subscribed => false)
  scope :unsubscribed, where(:subscribed => true)

  index({ email: 1 }, { background: true } )
  index({ subscribed: 1 }, { background: true } )

  def self.search(options = {})
    subscribers = Subscriber.desc(:created_at)
    subscribers = subscribers.where(:subscribed => options[:subscribed].to_s == 'true') if options[:subscribed].present?
    case options[:keyword].to_s
    when /^.+@.+$/
      subscribers = subscribers.where(:email => options[:keyword])
    else
      subscribers 
    end
  end

  def subscribe
    self.subscribed = true
    save
  end

  def unsubscribe
    self.subscribed = false
    self.unsubscribed_at = Time.now
    save
  end

end
