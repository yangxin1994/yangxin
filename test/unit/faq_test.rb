require 'test_helper'

class FaqTest < ActiveSupport::TestCase

	test "01 faq_type= instance method" do 
		clear(Faq)
		
		assert_raise(TypeError) { 
			Faq.create(faq_type: "type1", question: "question0", answer: "answer0") 
		}
		
		assert_raise(RangeError) { 
			Faq.create(faq_type: 0, question: "question0", answer: "answer0") 
		}
		
		assert_raise(RangeError) { 
			Faq.create(faq_type: "0", question: "question0", answer: "answer0") 
		}
		
		assert_raise(RangeError) { 
			Faq.create(faq_type: 3, question: "question0", answer: "answer0") 
		}
		
		assert_raise(RangeError) { 
			Faq.create(faq_type: 129, question: "question0", answer: "answer0") 
		}
		
		assert Faq.create(faq_type: 1, question: "question1", answer: "answer1")

		clear(Faq)
	end

	test "02 test rewrite instance method: save" do 
	  	clear(User, Faq)
	  	
		# origin save method must be work which is without user 
		faq = Faq.new(faq_type: 1, question: "question1", answer: "answer1")
		assert faq.save
		assert_equal faq.user_id, nil
	  	
	  	# new save method must be work which is with user
	  	user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 1
		user.save
		
		faq = Faq.new(faq_type: 1, question: "question2", answer: "answer2")
		assert faq.save(user)
		assert_equal faq.user, user
	  	
	  	clear(User, Faq)
	  end
	  
	  test "03 test rewrite instance method: update_attributes" do
		clear(User, Faq)
  	
		faq = Faq.new(faq_type: 1, question: "question1", answer: "answer1")
		assert faq.save
		
		# origin update_attributes method must be work which is without user 
		assert faq.update_attributes({question: "updated question1"})
		assert_equal faq.question, "updated question1"
	  	
	  	# new update_attributes method must be work which is with user
	  	user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 1
		user.save
		
		assert faq.update_attributes({question: "updated updated question1"}, user)	
		assert_equal faq.user, user
		assert_equal faq.question, "updated updated question1"
	  	
	  	clear(User, Faq)
	  end

	test "04 condition " do
		
		clear(Faq)
		
		Faq.create(faq_type: 1, question: "question1", answer: "answer1")
		Faq.create(faq_type: 2, question: "q2", answer: "answer2")

		assert_raise(TypeError){
			Faq.condition("type1", "")
		}

		assert_raise(RangeError){
			Faq.condition(-1, "")
		}

		assert_raise(ArgumentError){
			Faq.condition(4, "")
		}
		
		assert_equal Faq.condition(0, "question").count, 0
		assert_equal Faq.condition(0, "answer").count, 0
		assert_equal Faq.condition(1, "answer").count, 1
		assert_equal Faq.condition(3, "answer").count, 2
		
		clear(Faq)
		
	end
	

	test "05 find_by_type" do 
		clear(Faq)

		Faq.create(faq_type: 1, question: "question1", answer: "answer1")
		Faq.create(faq_type: 2, question: "q2", answer: "answer2")

		assert_raise(TypeError){
			Faq.find_by_type("type1")
		}

		assert_raise(RangeError){
			Faq.find_by_type(256)
		}
		
		assert_equal Faq.find_by_type(0).count, 0
		assert_equal Faq.find_by_type(1).count, 1
		assert_equal Faq.find_by_type(2).count, 1
		assert_equal Faq.find_by_type(3).count, 2
		assert_equal Faq.find_by_type(255).count, 2

		clear(Faq)
	end
end
