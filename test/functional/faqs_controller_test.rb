require 'test_helper'

class FaqsControllerTest < ActionController::TestCase

	test "01 should get index action and no faq record" do
		clear(Faq)
		get 'index', :format => :json
		assert_equal JSON.parse(@response.body), []		
		clear(Faq)
	end

	test "02 should post create action which is without login" do
		clear(User, Faq)
	
		post 'create', :faq => {faq_type: 1, question: "question1", answer: "answer1"}, :format => :json
		retval = @response.body.to_i
		assert_equal retval, ErrorEnum::REQUIRE_LOGIN
		
		clear(User,Faq)
	end
	
	test "03 should post create action with login, but not admin user" do
		clear(User, Faq)
		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 0
		user.save
	
		sign_in(user.email, Encryption.decrypt_password(user.password))
		post 'create', :faq => {faq_type: 1, question: "question1", answer: "answer1"}, :format => :json
		retval = @response.body.to_i
		assert_equal retval, ErrorEnum::REQUIRE_ADMIN
		sign_out
		
		clear(User,Faq)
	end
	
	test "04 should post create action with admin user login" do
		clear(User, Faq)
		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 1
		user.save
	
		sign_in(user.email, Encryption.decrypt_password(user.password))
		post 'create', :faq => {faq_type: "Type1", question: "question1", answer: "answer1"}, :format => :json
		retval = @response.body.to_i
		assert_equal retval, ErrorEnum::TYPE_ERROR
		
		post 'create', :faq => {faq_type: 256, question: "question1", answer: "answer1"}, :format => :json
		retval = @response.body.to_i
		assert_equal retval, ErrorEnum::RANGE_ERROR
		
		post 'create', :faq => {faq_type: 1, question: "question1", answer: "answer1"}, :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval["question"], "question1"
		sign_out
		
		clear(User,Faq)
	end

	test "05 should post update action which is with admin " do
		clear(User, Faq)
		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 1
		user.save
		
		user2 = User.new(email: "test2@example.com", password: Encryption.encrypt_password("123456"))
		user2.status = 2
		user2.role = 1
		user2.save
	
		sign_in(user.email, Encryption.decrypt_password(user.password))
		post 'create', :faq => {faq_type: 1, question: "question1", answer: "answer1"}, :format => :json
		retval = JSON.parse(@response.body)
		sign_out
		
		sign_in(user2.email, Encryption.decrypt_password(user2.password))
		post 'update', :id => retval["_id"], :faq => {question: "updated question1"}, :format => :json
		
		retval = Faq.find(retval["_id"])
		assert_equal retval["question"], "updated question1"
		assert_equal retval.user, user2
		sign_out

		clear(User,Faq)
	end
	
	test "06 should destroy action which is with admin " do
		clear(User, Faq)
		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 1
		user.save
	
		sign_in(user.email, Encryption.decrypt_password(user.password))
		post 'create', :faq => {faq_type: 1, question: "question1", answer: "answer1"}, :format => :json
		retval = JSON.parse(@response.body)

		post 'destroy', :id => retval["_id"], :format => :json
		
		retval = Faq.where(_id: retval["_id"]).first
		assert_equal retval, nil
		sign_out

		clear(User,Faq)
	end

	test "07 should get find_by_type action" do
	
		clear(User, Faq)
		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 1
		user.save
	
		sign_in(user.email, Encryption.decrypt_password(user.password))
		post 'create', :faq => {faq_type: 1, question: "question1", answer: "answer1"}, :format => :json
		post 'create', :faq => {faq_type: 2, question: "question2", answer: "answer1"}, :format => :json
		post 'create', :faq => {faq_type: 4, question: "question4", answer: "answer1"}, :format => :json
		
		get 'condition', :type => 0, :value => "", :format => :json
		retval = @response.body.to_i
		assert_equal retval, ErrorEnum::ARG_ERROR
		
		get 'condition', :format => :json
		retval = @response.body.to_i
		assert_equal retval, ErrorEnum::ARG_ERROR
		
		get 'condition', :type => 1, :value => "user", :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 0
		
		get 'condition', :type => 7, :value => "answer1", :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 3

		get 'condition', :type => 0, :value => "question1", :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 0

		get 'condition', :type => 0, :value => "answer1", :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 0
		
		sign_out
		clear(User, Faq)
	end

	test "08 should get types action" do 
		clear(User, Faq)

		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 1
		user.save

		sign_in(user.email, Encryption.decrypt_password(user.password))
		post 'create', :faq => {faq_type: 1, question: "question1", answer: "answer1"}, :format => :json
		post 'create', :faq => {faq_type: 2, question: "question2", answer: "answer1"}, :format => :json
		post 'create', :faq => {faq_type: 4, question: "question4", answer: "answer1"}, :format => :json

		get 'types', :type => "Type1", :format => :json
		retval = @response.body.to_i
		assert_equal retval, ErrorEnum::TYPE_ERROR

		get 'types', :type => 256, :format => :json
		retval = @response.body.to_i
		assert_equal retval, ErrorEnum::RANGE_ERROR
		
		get 'types', :type => 1, :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 1
		
		get 'types', :type => 7, :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 3

		get 'types', :type => 0, :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 0

		get 'types', :type => 255, :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 3

		clear(User, Faq)
	end
	
end
