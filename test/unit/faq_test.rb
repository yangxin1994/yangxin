require 'test_helper'

class FaqTest < ActiveSupport::TestCase

	test "00 init test db data" do
		clear(User, Faq)
		@@normal_user = User.new(email: "test@example.com")
		@@normal_user.role = 0
		@@normal_user.save
		@@admin_user = User.new(email:"test2@example.com")
		@@admin_user.role = 1
		@@admin_user.save
	end
	
	test "99 clear test db data" do 
		clear(User, Faq)
	end 

	test "01 a normal user create new faq from method: create_by_user" do
		if @@normal_user then
			assert !Faq.create_by_user(@@normal_user, "type1", "question1", "answer1")
		end
	end
   
	test "02 a admin user create new faq from method: create_by_user" do
		if @@admin_user then
			assert Faq.create_by_user(@@admin_user, "type2", "question2", "answer2")
		end
	end

	test "03 a admin user udpate faq from method: update_by_user" do
		faq = Faq.where(faq_type: "type2").first
		if @@admin_user and faq then
			Faq.update_by_user(faq.id, @@admin_user, {question: "updated question2"})
			assert Faq.where(faq_type: "type2").first.question.to_s == "updated question2"
		end
	end
	
	test "04 a admin user get faqs with condition from method: condition" do
		faq = Faq.condition("type", "type2").first
  	assert_equal faq.question, "updated question2"
    faq = Faq.condition("question", "updated question2").first
    assert_equal faq.question, "updated question2"
    faq = Faq.condition("answer", "ans").first
    assert_equal faq.question, "updated question2"
    
	end

	test "05 a admin user destroy faq from method: destroy_by_user" do
		faq = Faq.where(faq_type: "type2").first
		if @@admin_user and faq then
			assert Faq.destroy_by_user(faq.id, @@admin_user)
		end
	end
	
end
