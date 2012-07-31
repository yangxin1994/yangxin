require 'test_helper'
require 'error_enum'

class MessageTest < ActiveSupport::TestCase
	 #test "the truth" do
	   # assert true
	 # end

	test "message show" do
		# clear(Message, User)

		jesse = init_jesse
		oliver = init_oliver

		retval1 = Message.create_new("title1", "content1", jesse._id, 0, [])
		message_id = retval1.get_id

		retval = Message.find_by_id(message_id)
		assert_equal "title1", retval["title"]
		assert_equal "content1", retval["content"]
		assert_equal jesse._id, retval["sender_id"]
		assert_equal 0, retval["message_type"]
		assert true
	end

		test "get messages" do
		# clear(User, Message)

		jesse = init_jesse
		oliver = init_oliver
		lisa = init_lisa
                set_as_admin(jesse)

		Message.create_new("title1", "content1", jesse._id, 0, [])
		Message.create_new("title2", "content2", jesse._id, 1, [oliver._id])
		Message.create_new("title3", "content3", jesse._id, 1, [oliver._id])
		Message.create_new("title4", "content4", jesse._id, 0, [])
		Message.create_new("title5", "content5", jesse._id, 1, [lisa._id])
		Message.create_new("title6", "content6", jesse._id, 1, [lisa._id])
		Message.create_new("title7", "content7", jesse._id, 1, [oliver._id, lisa._id])
		Message.create_new("title8", "content8", jesse._id, 1, [oliver._id, lisa._id])

		retval = Message.get_messages()
		assert_equal 8, retval.size
		
		retval = Message.get_messages(oliver._id)
		assert_equal 6, retval.size

		retval = Message.get_message(lisa._id)
		assert_equal 6, retval.size

		retval = Message.get_messages("010203ed9302di9")
		assert_equal ErrorEnum::USER_NOT_EXIST, retval
	end

	test "message creation" do
		clear(User)

		jesse = init_jesse
		oliver = init_oliver
		lisa = init_lisa
                set_as_admin(jesse)

		retval = Message.create_new("title_1","content_1",jesse._id,1 , [])
		assert_equal ErrorEnum::RECEIVER_CAN_NOT_BLANK, retval
		
		retval = Message.create_new("", "content_2", jesse._id, 0 , [])
		assert_equal ErrorEnum::TITLE_CAN_NOT_BLANK, retval
		
		retval = Message.create_new("title_2", "", jesse._id, 0 , [])
		assert_equal ErrorEnum::CONTENT_CAN_NOT_BLANK, retval

		retval = Message.create_new("title_3", "content_3", oliver._id, 0 , [])
		assert_equal ErrorEnum::AUTHROZIED, retval

		retval = Message.create_new("title_1", "content_3", jesse._id, 1 , [oliver._id, lisa._id])
		assert_equal "title_1", retval["title"]
		assert_equal "content_3", retval["content"]
		assert_equal jesse._id, retval["sender_id"]
		assert_equal 1, retval["message_type"]
	end

	test "message update" do
		clear(Message)

		# jesse = init_jesse
		# set_as_admin(jesse)

		# retval = Message.create_new("title1", "connt1", jesse._id, 0, [])
		# message_id = retval._id

		# message = Message.find_by_id(message_id)
		# assert_equal Message, message.class
		# update_message = Message.new("title1", "content1")
		# retval = message.update(update_message)
		# assert_equal true, retval
		# retval = Message.get_object(jesse, message_id)
		# assert_equal "title1", retval["title"]
	end

	test "message delete" do
		# clear(User, Message)

		jesse = init_jesse
		oliver = init_oliver

		retval = Message.create_new("title1", "content1", jesse._id, 0, [])
		message_id = retval._id

		message = Message.find_by_id(message_id)
		assert_equal Message, message.class

		retval = message.destroy
		assert_equal retval, true

		retval = Message.find_by_id(message_id)
		assert_equal nil, retval
	end

	test "get number of unlooked" do
		# clear(User, Message)
		
		jesse = init_jesse
		oliver = init_oliver
		set_as_admin(jesse)

		retval = Message.create_new("title1", "connt1", jesse._id, 0, [])
		retval1 = Message.get_number_unlooked(oliver._id, oliver.last_visit_time)
		assert_equal 1, retval1
		retval2 = retval.get_messages(oliver._id)
		retval = Message.create_new("title2", "content2", jesse._id, 1, [oliver._id])
		retval = Message.create_new("title3", "content3", jesse._id, 1, [oliver._id])
		retval1 = Message.get_number_unlooked(oliver._id, oliver.last_visit_time)
		assert_equal 2, retval1
	end	
end
