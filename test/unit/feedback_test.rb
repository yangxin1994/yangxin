require 'test_helper'

class FeedbackTest < ActiveSupport::TestCase

	test "01 find_by_type" do
	
		clear(Feedback)
		
		assert_raise(TypeError) { 
			Feedback.create(feedback_type: "type1", title: "title0", content: "content0") 
		}
		
		assert_raise(RangeError) { 
			Feedback.create(feedback_type: 0, title: "title0", content: "content0") 
		}
		
		assert_raise(RangeError) { 
			Feedback.create(feedback_type: 3, title: "title0", content: "content0") 
		}
		
		assert_raise(RangeError) { 
			Feedback.create(feedback_type: 129, title: "title0", content: "content0") 
		}
		
		Feedback.create(feedback_type: 1, title: "title1", content: "content1")
		Feedback.create(feedback_type: 2, title: "q2", content: "content2")
		
		assert_equal Feedback.find_by_type(0, "title").count, 0
		assert_equal Feedback.find_by_type(0, "content").count, 0
		assert_equal Feedback.find_by_type(1, "content").count, 1
		assert_equal Feedback.find_by_type(3, "content").count, 2
		
		clear(Feedback)
		
	end

=begin
	test "02 reply method" do 
		clear(User, Feedback, Message)
		
		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 0
		user.save
		
		user2 = User.new(email: "test2@example.com", password: Encryption.encrypt_password("123456"))
		user2.status = 2
		user2.role = 1
		user2.save
		
		f = Feedback.create(feedback_type: 1, title: "title1", content: "content1")
		f.question_user = user 
		f.save
		
		assert_equal Feedback.reply(f.id.to_s, user, "illegel user"), false
		assert_equal Feedback.reply(f.id.to_s, user2, "legel user"), true
		
		clear(User, Feedback, Message)
	end
=end
end

