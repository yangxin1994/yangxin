require "error_enum"
class Message

  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::ValidationsExt
  include FindTool

  field :title, :type => String
  field :content, :type => String
  # 0 the message is sent to all users
  # 1 the message is sent to special users
  field :type, :type => Integer, default: 0

  belongs_to :sender, :class_name => "User", :inverse_of => :sended_messages
  has_and_belongs_to_many :receiver, class_name: "User", inverse_of: :messages

  default_scope order_by(:created_at.desc)

  validates :title, :presence => true
  # validates :content, :presence => true

  scope :unread, ->(t){where(:updated_at.gt => t)}
  scope :readed, ->(t){where(:updated_at.lt => t)}

  index({ updated_at: 1 }, { background: true } )
end
