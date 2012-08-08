<<<<<<< HEAD
=======
# encoding: utf-8
>>>>>>> master
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
<<<<<<< HEAD
	include Mongoid::Document
	include Mongoid::Timestamps
	extend Mongoid::FindHelper
	
	field :title, :type => String
	field :content, :type => String
	field :sender_id, :type => String
	# 0 the messge is sent to all users
	# 1 the messge is sent to special users
	field :message_type, :message_type => Integer, default: 0

	belongs_to :user

	
	def get_id
    return self._id.to_s
	end

	#*description*: get the messages array of user
	#
	#*params*:
	#
	#*retval*:
	#* the messages object array
	#* USER_NOT_EXIST: when the user not exists
	def self.get_messages(user_id)
		message_objs = []
		user = User.find_by_id(user_id)
		return ErrorEnum::USER_NOT_EXIST if user.nil? 
		user.update_last_visit_time 
		user.save
		user.message_ids.each do |message_id|
			message = Massage.find_by_id(message_id)
			message_objs << message
            	end
		return message_objs      
	end
          
	#*description*: get the number of user's messages which the user hasn't looked
	#
	#*params*:
	#* id of the user doing this operation
	#
	#*retval*:
	#* the number of user's unlooked messages
	#* USER_NOT_EXIST :when the user not exists
	def self.get_number_unlooked(user_id, last_visit_time)
		user = User.find_by_id(user_id)
		return ErrorEnum::USER_NOT_EXIST if user.nil?
		message_objs=Array.new
		message_objs = self.get_messages(user_id)
		message_objs.each do |message|
			number = number + 1 if message.create_time.to_i > user.last_visit_time
		end
		return number
	end

	#*description*: create a new message
	#
	#*params*:
	#* title of the message
	#* content of the message
	#* id of the current user
	#* type of the message
	#* ids of the receivers doing this operation
	#
	#*retval*:
	#* the new message instance: when successfully created
	#* THERE_ARE_SOME_RECEIVERS_NOT_EXIST : when there are some receivers not exist
	#* UNAUTHROZIED: when the sender is not administrator
	#* RECEIVER_CAN_NOT_BLANK: when receiver not exsit
	#* TITLE_CAN_NOT_BLANK: when the title of the message is blank
	#* CONTENT_CAN_NOT_BLANK: when the content of the message is blank
	def self.create_new(title, content, sender_id, message_type, receiver_ids)
		return ErrorEnum::UNAUTHROZIED unless User.find_by_id(sender_id).is_admin
		return ErrorEnum::RECEIVER_CAN_NOT_BLANK if message_type == 1 and receiver_ids.size == 0
		return ErrorEnum::TITLE_CAN_NOT_BLANK if title == ""
		return ErrorEnum::CONTENT_CAN_NOT_BLANK if content == ""
		message = Message.new(:title => title, :content => content, :sender_id => sender_id, :message_type => message_type)
		if message_type == 0
			User.all.each do |user|
 				user.message_ids << message._id
				user.save
			end
		else 
			receiver_ids.each do |receiver_id|
				receiver = User.find_by_id(receiver_id)
				if receiver.nil?  
					return ErrorEnum::THERE_ARE_SOME_RECEIVERS_NOT_EXIST
				else 
					receiver.message_ids << message._id
					receiver.save 
				end
			end
		end
		message.save           
		return message
	end

	#*description*:the user destroy a message
	#
	#*params*:
	#* id of the message doing this operation
	#
	#*retval*:
	#* true if the message is deleted, false if the message not deleted
	def destroy
		User.all.each do |user|
			user.message_ids.delete(self._id)
		end
		super
	end

	#*description*: update a message
	#
	#*params*:
	#* the message object to be updated
	#
	#*retval*:
	#* the updated message object
	def self.update_message(message_obj)
		self.title = message_obj["title"]
		self.content = message_obj["content"]
		return self.save
	end
=======
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Mongoid::FindHelper

  field :title, :type => String
  field :content, :type => String
  # 0 the message is sent to all users
  # 1 the message is sent to special users
  field :type, :type => Integer, default: 0

  belongs_to :sender, :class_name => "User", :inverse_of => :sended_messages
  
  validates :title, :presence => true
  validates :content, :presence => true

  scope :unread, ->(t){where(:updated_at.gt => t)}
  scope :readed, ->(t){where(:updated_at.lt => t)}
  
>>>>>>> master
end
