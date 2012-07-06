require 'test_helper'

class FeedbackTest < ActiveSupport::TestCase

	test "00 init test db data" do
		clear(User, Feedback)
		@@normal_user = User.new(email: "test@example.com")
		@@normal_user.role = 0
		@@normal_user.save
		@@admin_user = User.new(email:"test2@example.com")
		@@admin_user.role = 1
		@@admin_user.save
	end
	
	test "99 clear test db data" do 
		clear(User, Feedback)
	end 

	test "01 a normal user create new feedback from method: create" do
		if @@normal_user then
			assert Feedback.create("type1", "title1", "content1", @@normal_user)
		end
	end
   
	test "02 a admin user create new feedback from method: create" do
		if @@admin_user then
			assert Feedback.create("type2", "title2", "content2", @@admin_user)
		end
	end

	test "03 a normal user udpate feedback from method: update" do
		feedback = Feedback.where(feedback_type: "type1").first
		if @@normal_user and feedback then
			assert Feedback.update(feedback.id, {title: "updated title1"}, @@normal_user)
			assert Feedback.where(feedback_type: "type1").first.title.to_s == "updated title1"
		end
	end
	
=begin
	test "04 a admin user reply a feedback" do 
		clear(Message)
		
		feedback = Feedback.where(feedback_type: "type2").first
		Feedback(feedback.id, @@admin_user, "test reply")
		
		message = Message.where(sender_id: @@admin_user.id.to_s, content: "test reply").first
		assert !message.nil?
		
		if message then
			feedback.is_answer = true
			feedback.save
		end
		
		clear(Message)
	end
=end

	test "05 get feedback with condition from method: condition" do
		feedback = Feedback.condition("type", "type2").first
  	assert_equal feedback.title, "title2"
    feedback = Feedback.condition("title", "title2").first
    assert_equal feedback.title, "title2"
    feedback = Feedback.condition("is_answer", false).first
    assert_equal feedback.title, "updated title1"
    feedback = Feedback.condition("is_answer", true).first
    assert_equal feedback, nil
	end
	
	test "06 get feedback from scope " do
		feedback = Feedback.answered.first
		assert_equal feedback, nil
		feedback = Feedback.unanswer.first
		assert_equal feedback.title, "updated title1"	
	end 

	test "07 a normal user and a amdin user destroy a feedback from method: destroy" do
		feedback = Feedback.where(feedback_type: "type1").first
		if @@admin_user and feedback then
			assert !Feedback.destroy(feedback.id, @@admin_user)
			assert Feedback.destroy(feedback.id, @@normal_user)
		end
	end

end
