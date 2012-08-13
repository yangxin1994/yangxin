require 'test_helper'

class FeedbackTest < ActiveSupport::TestCase

	test "01 verify_feedback_type method" do 
		clear(Feedback)
		
		assert_equal Feedback.verify_feedback_type("type1"), ErrorEnum::FEEDBACK_TYPE_ERROR
		assert_equal Feedback.verify_feedback_type(0), ErrorEnum::FEEDBACK_RANGE_ERROR
		assert_equal Feedback.verify_feedback_type(1), true
		assert_equal Feedback.verify_feedback_type(129), ErrorEnum::FEEDBACK_RANGE_ERROR

		clear(Feedback)
	end

	test "02 find_by_id" do 
	  	clear(Feedback)
	  	
		feedback = Feedback.create(feedback_type: 1, title: "title1", content: "content1")
		assert_equal Feedback.find_by_id("4fff96616c6eea1204022005"), ErrorEnum::FEEDBACK_NOT_EXIST
		assert_equal Feedback.find_by_id(feedback.id), feedback
	  	
	  	clear(Feedback)
	end

	test "03 create_feedback" do 
		clear(Feedback, User)

		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.save

		feedback = Feedback.create_feedback({feedback_type: 1, title: "title1", content: "content1"}, user)
		assert_equal feedback.question_user, user
		assert_equal feedback.title, "title1"
		assert_equal feedback.feedback_type, 1

		assert_equal Feedback.create_feedback({feedback_type: "type1", title: "title1"}, user), ErrorEnum::FEEDBACK_TYPE_ERROR
		assert_equal Feedback.create_feedback({feedback_type: 0, title: "title1"}, user), ErrorEnum::FEEDBACK_RANGE_ERROR
		assert_equal Feedback.create_feedback({feedback_type: 1, content: "content1"}, user), ErrorEnum::FEEDBACK_SAVE_FAILED
		assert_equal Feedback.create_feedback({feedback_type: 129, title: "title1"}, user), ErrorEnum::FEEDBACK_RANGE_ERROR

		clear(Feedback, User)
	end

	test "04 update_feedback" do
		clear(User, Feedback)
  	
		user = User.create(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user2 = User.create(email: "test2@example.com", password: Encryption.encrypt_password("123456"))
		
		feedback = Feedback.create_feedback({feedback_type: 1, title: "title1", content: "content1"}, user)
		assert_equal feedback.question_user, user
		assert_equal feedback.title, "title1"
		assert_equal feedback.feedback_type, 1

		feedback = Feedback.update_feedback(feedback.id, {feedback_type: 2, title: "updated title1"}, user)		
		assert_equal feedback.question_user, user
		assert_equal feedback.title, "updated title1"
		assert_equal feedback.feedback_type, 2

		feedback.is_answer = true
		assert_equal feedback.save, true

		assert_equal Feedback.update_feedback(feedback.id,{feedback_type: "type1", title: "title1"}, user), ErrorEnum::FEEDBACK_TYPE_ERROR
		assert_equal Feedback.update_feedback(feedback.id,{feedback_type: 0, title: "title1"}, user), ErrorEnum::FEEDBACK_RANGE_ERROR
		assert_equal Feedback.update_feedback(feedback.id,{feedback_type: 129, title: "title1"}, user), ErrorEnum::FEEDBACK_RANGE_ERROR
		assert_equal Feedback.update_feedback(feedback.id,{feedback_type: 4, title: "title1"}, user2), ErrorEnum::FEEDBACK_NOT_CREATOR
		assert_equal Feedback.update_feedback(feedback.id,{feedback_type: 4, title: "title1"}, user), ErrorEnum::FEEDBACK_CANNOT_UPDATE

		#create without user
		feedback = Feedback.create_feedback({feedback_type: 1, title: "title1", content: "content1"})
		assert_equal feedback.question_user, nil
		assert_equal feedback.title, "title1"
		assert_equal feedback.feedback_type, 1

		assert_equal Feedback.update_feedback(feedback.id,{feedback_type: 4, title: "title1"}, user2), ErrorEnum::FEEDBACK_CANNOT_UPDATE


		assert_equal Feedback.all.count, 2
	  	
	  	clear(User, Feedback)
	end

	test "05 destroy_by_id " do
		
		clear(Feedback)
		
		user = User.create(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user2 = User.create(email: "test2@example.com", password: Encryption.encrypt_password("123456"))

		feedback = Feedback.create_feedback({feedback_type: 1, title: "title1", content: "content1"}, user)
		assert_equal feedback.question_user, user
		assert_equal feedback.title, "title1"
		assert_equal feedback.feedback_type, 1

		assert_equal Feedback.destroy_by_id("4fff96616c6eea1204022005", user), ErrorEnum::FEEDBACK_NOT_EXIST
		assert_equal Feedback.destroy_by_id(feedback.id, user2), ErrorEnum::FEEDBACK_NOT_CREATOR
		assert_equal Feedback.destroy_by_id(feedback.id, user), true
		
		clear(Feedback)
		
	end

	test "06 list_by_type" do 
		clear(Feedback)

		user = User.create(email: "test@example.com", password: Encryption.encrypt_password("123456"))

		Feedback.create_feedback({feedback_type: 1, title: "title1", content: "content1"}, user)
		Feedback.create_feedback({feedback_type: 2, title: "title1", content: "content1"}, user)
		Feedback.create_feedback({feedback_type: 4, title: "title1", content: "content1"}, user)
		Feedback.create_feedback({feedback_type: 8, title: "title1", content: "content1"}, user)
		Feedback.create_feedback({feedback_type: 16, title: "title1", content: "content1"}, user)
		Feedback.create_feedback({feedback_type: 32, title: "title1", content: "content1"}, user)
		Feedback.create_feedback({feedback_type: 64, title: "title1", content: "content1"}, user)
		Feedback.create_feedback({feedback_type: 128, title: "title1", content: "content1"}, user)

		assert_equal Feedback.all.count, 8
		assert_equal Feedback.list_by_type(1).count, 1
		assert_equal Feedback.list_by_type(4).count, 1
		assert_equal Feedback.list_by_type(16).count, 1
		assert_equal Feedback.list_by_type(64).count, 1
		assert_equal Feedback.list_by_type(7).count, 3
		assert_equal Feedback.list_by_type(255).count, 8

		clear(Feedback)
	end

	test "07 list_by_type_and_value" do 
		clear(Feedback)

		user = User.create(email: "test@example.com", password: Encryption.encrypt_password("123456"))

		Feedback.create_feedback({feedback_type: 1, title: "title1", content: "content1"}, user)
		Feedback.create_feedback({feedback_type: 1, title: "title2", content: "content2"}, user)
		Feedback.create_feedback({feedback_type: 2, title: "title1", content: "content1"}, user)
		Feedback.create_feedback({feedback_type: 4, title: "title1", content: "content1"}, user)
		Feedback.create_feedback({feedback_type: 8, title: "title1", content: "content1"}, user)
		Feedback.create_feedback({feedback_type: 16, title: "title1", content: "content1"}, user)
		Feedback.create_feedback({feedback_type: 32, title: "title1", content: "content1"}, user)
		Feedback.create_feedback({feedback_type: 64, title: "title1", content: "content1"}, user)
		Feedback.create_feedback({feedback_type: 128, title: "title1", content: "content1"}, user)

		assert_equal Feedback.all.count, 9
		assert_equal Feedback.list_by_type_and_value(1, nil).count, 2
		assert_equal Feedback.list_by_type_and_value(1, "content1").count, 1
		assert_equal Feedback.list_by_type_and_value(1, "title1").count, 1
		assert_equal Feedback.list_by_type_and_value(255, "title").count, 9
		assert_equal Feedback.list_by_type_and_value(255, "title1").count, 8

		clear(Feedback)
	end

	test "08 reply method" do 
		clear(User, Feedback, Message)
		
		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 0
		user.save
		
		user2 = User.new(email: "test2@example.com", password: Encryption.encrypt_password("123456"))
		user2.status = 2
		user2.role = 1
		user2.save
		
		assert_equal Feedback.all.count, 0
		f = Feedback.create_feedback({feedback_type: 1, title: "title1", content: "content1"}, user)
		assert_equal f.class, Feedback
		assert_equal Feedback.all.count, 1
		
		assert_equal Message.all.count, 0
		assert_equal Feedback.reply(f.id.to_s, user, "illegel user"), ErrorEnum::REQUIRE_ADMIN
		message = Feedback.reply(f.id.to_s, user2, "legel user")
		assert_equal message.class, Message

		assert_equal Message.all.count, 1
		
		clear(User, Feedback, Message)
	end

end

