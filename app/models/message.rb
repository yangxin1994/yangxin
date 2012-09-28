# encoding: utf-8
require "error_enum"
# the message object has the following structure
# {
#    message_id:   id of the message  
#    title:        title of the message
#    content:      content of the message
#    sender_id:    id of the sender
#    type:         whether the message is sent to all users 
#  } 
class Message

  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::ValidationsExt
  extend Mongoid::FindHelper

  field :title, :type => String
  field :content, :type => String
  # 0 the message is sent to all users
  # 1 the message is sent to special users
  field :type, :type => Integer, default: 0

  belongs_to :sender, :class_name => "User", :inverse_of => :sended_messages
  has_and_belongs_to_many :receiver, class_name: "User", inverse_of: :messages

  validates :title, :presence => true
  validates :content, :presence => true

  scope :unread, ->(t){where(:updated_at.gt => t)}
  scope :readed, ->(t){where(:updated_at.lt => t)}

end
