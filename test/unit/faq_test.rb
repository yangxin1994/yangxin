require 'test_helper'

class FaqTest < ActiveSupport::TestCase

	test "01 verify_faq_type method" do 
		clear(Faq)
		
		assert_equal Faq.verify_faq_type("type1"), ErrorEnum::FAQ_TYPE_ERROR
		assert_equal Faq.verify_faq_type(0), ErrorEnum::FAQ_RANGE_ERROR
		assert_equal Faq.verify_faq_type(1), true
		assert_equal Faq.verify_faq_type(129), ErrorEnum::FAQ_RANGE_ERROR

		clear(Faq)
	end

	test "02 find_by_id" do 
	  	clear(Faq)
	  	
		faq = Faq.create(faq_type: 1, question: "question1", answer: "answer1")
		assert_equal Faq.find_by_id("4fff96616c6eea1204022005"), ErrorEnum::FAQ_NOT_EXIST
		assert_equal Faq.find_by_id(faq.id), faq
	  	
	  	clear(Faq)
	end

	test "03 create_faq" do 
		clear(Faq, User)

		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.save

		faq = Faq.create_faq({faq_type: 1, question: "question1", answer: "answer1"}, user)
		assert_equal faq.user, user
		assert_equal faq.question, "question1"
		assert_equal faq.faq_type, 1

		assert_equal Faq.create_faq({faq_type: "type1", question: "question1"}, user), ErrorEnum::FAQ_TYPE_ERROR
		assert_equal Faq.create_faq({faq_type: 0, question: "question1"}, user), ErrorEnum::FAQ_RANGE_ERROR
		assert_equal Faq.create_faq({faq_type: 129, question: "question1"}, user), ErrorEnum::FAQ_RANGE_ERROR
		assert_equal Faq.create_faq({faq_type: 128, question: "question1"}, user), ErrorEnum::FAQ_SAVE_FAILED

		clear(Faq, User)
	end

	test "04 update_faq" do
		clear(User, Faq)
  	
		user = User.create(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user2 = User.create(email: "test2@example.com", password: Encryption.encrypt_password("123456"))
		
		faq = Faq.create_faq({faq_type: 1, question: "question1", answer: "answer1"}, user)
		assert_equal faq.user, user
		assert_equal faq.question, "question1"
		assert_equal faq.faq_type, 1

		faq = Faq.update_faq(faq.id, {faq_type: 2, question: "updated question1", answer: "updated answer1"}, user2)		
		assert_equal faq.user, user2
		assert_equal faq.question, "updated question1"
		assert_equal faq.faq_type, 2

		assert_equal Faq.update_faq(faq.id,{faq_type: "type1", question: "question1"}, user), ErrorEnum::FAQ_TYPE_ERROR
		assert_equal Faq.update_faq(faq.id,{faq_type: 0, question: "question1"}, user), ErrorEnum::FAQ_RANGE_ERROR
		assert_equal Faq.update_faq(faq.id,{faq_type: 129, question: "question1"}, user), ErrorEnum::FAQ_RANGE_ERROR

		assert_equal Faq.all.count, 1
	  	
	  	clear(User, Faq)
	end

	test "05 destroy_by_id " do
		
		clear(Faq)
		
		user = User.create(email: "test@example.com", password: Encryption.encrypt_password("123456"))

		faq = Faq.create_faq({faq_type: 1, question: "question1", answer: "answer1"}, user)
		assert_equal faq.user, user
		assert_equal faq.question, "question1"
		assert_equal faq.faq_type, 1

		assert_equal Faq.destroy_by_id("4fff96616c6eea1204022005"), ErrorEnum::FAQ_NOT_EXIST
		assert_equal Faq.destroy_by_id(faq.id), true
		
		clear(Faq)
		
	end

	test "06 list_by_type" do 
		clear(Faq)

		user = User.create(email: "test@example.com", password: Encryption.encrypt_password("123456"))

		Faq.create_faq({faq_type: 1, question: "question1", answer: "answer1"}, user)
		Faq.create_faq({faq_type: 2, question: "question1", answer: "answer1"}, user)
		Faq.create_faq({faq_type: 4, question: "question1", answer: "answer1"}, user)
		Faq.create_faq({faq_type: 8, question: "question1", answer: "answer1"}, user)
		Faq.create_faq({faq_type: 16, question: "question1", answer: "answer1"}, user)
		Faq.create_faq({faq_type: 32, question: "question1", answer: "answer1"}, user)
		Faq.create_faq({faq_type: 64, question: "question1", answer: "answer1"}, user)
		Faq.create_faq({faq_type: 128, question: "question1", answer: "answer1"}, user)

		assert_equal Faq.all.count, 8
		assert_equal Faq.list_by_type(1).count, 1
		assert_equal Faq.list_by_type(4).count, 1
		assert_equal Faq.list_by_type(16).count, 1
		assert_equal Faq.list_by_type(64).count, 1
		assert_equal Faq.list_by_type(7).count, 3
		assert_equal Faq.list_by_type(255).count, 8

		clear(Faq)
	end

	test "07 list_by_type_and_value" do 
		clear(Faq)

		user = User.create(email: "test@example.com", password: Encryption.encrypt_password("123456"))

		Faq.create_faq({faq_type: 1, question: "question1", answer: "answer1"}, user)
		Faq.create_faq({faq_type: 1, question: "question2", answer: "answer2"}, user)
		Faq.create_faq({faq_type: 2, question: "question1", answer: "answer1"}, user)
		Faq.create_faq({faq_type: 4, question: "question1", answer: "answer1"}, user)
		Faq.create_faq({faq_type: 8, question: "question1", answer: "answer1"}, user)
		Faq.create_faq({faq_type: 16, question: "question1", answer: "answer1"}, user)
		Faq.create_faq({faq_type: 32, question: "question1", answer: "answer1"}, user)
		Faq.create_faq({faq_type: 64, question: "question1", answer: "answer1"}, user)
		Faq.create_faq({faq_type: 128, question: "question1", answer: "answer1"}, user)

		assert_equal Faq.all.count, 9
		assert_equal Faq.list_by_type_and_value(1, nil).count, 2
		assert_equal Faq.list_by_type_and_value(1, "answer1").count, 1
		assert_equal Faq.list_by_type_and_value(1, "question1").count, 1
		assert_equal Faq.list_by_type_and_value(255, "question").count, 9
		assert_equal Faq.list_by_type_and_value(255, "question1").count, 8

		clear(Faq)
	end

end
