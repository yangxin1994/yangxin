# already tidied up
class Newsletter
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::ValidationsExt
  extend Mongoid::FindHelper
  include Mongoid::CriteriaExt

  field :subject, type: String
  field :title, type: String
  field :status, type: Integer, default: 0
  field :columns, type: Hash, default: {}
  field :is_tested, type: Boolean, default: false
  field :is_deleted, type: Boolean, default: false

  has_and_belongs_to_many :subscribers

  default_scope where(:is_deleted => false)
  scope :editing, where(:status => 0)
  scope :delivering, where(:status => -1)
  scope :delivered, where(:status => 1)
  scope :canceled, where(:status => -2)

  scope :find_by_status, ->(_status) { _status.present? ? where(:status => _status) : self.all }

  index({ is_deleted: 1 }, { background: true } )
  index({ status: 1 }, { background: true } )

  def present_admin
    present_attrs :_id, :title, :subject, :status, :columns, :is_tested, :is_deleted
    present_add   :created_at=> self.created_at.strftime("%Y-%m-%d")
  end


  def cancel
    self.status = -2
    self.save
    Sidekiq.redis{|r| r.set('news_flag', '0')}
  end
end
