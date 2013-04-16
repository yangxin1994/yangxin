class Subscriber
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::ValidationsExt
  extend Mongoid::FindHelper

  field :email, type: String
  field :status, type: Integer, default: 0
  field :is_deleted, type: Boolean, default: false

  has_and_belongs_to_many :newsletters

  # Validations

  default_scope where(:is_deleted => false)

  def unsubscribe
    self.is_deleted = true
    save
  end

end
