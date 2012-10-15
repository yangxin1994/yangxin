require 'test_helper'

class Admin::FaqsControllerTest < ActionController::TestCase

	test "01 should get index action " do
		clear(User,Faq)

		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 4
		user.role = 1
		user.save
	
		auth_key = sign_in(user.email, "123456")

		get 'index', :format => :json, :auth_key => auth_key
		assert_equal JSON.parse(@response.body)["value"], []

		sign_out(auth_key)

		clear(User,Faq)
	end

	test "02 should post create action which is without login" do
		clear(User, Faq)
	
		post 'create', :faq => {faq_type: 1, question: "question1", answer: "answer1"}, :format => :json
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::REQUIRE_LOGIN, result["value"]["error_code"]
		
		clear(User,Faq)
	end
	
	test "03 should post create action with login, but not admin user" do
		clear(User, Faq)
		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 4
		user.role = 0
		user.save
	
		auth_key = sign_in(user.email, "123456")
		post 'create', :faq => {faq_type: 1, question: "question1", answer: "answer1"}, :format => :json, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::REQUIRE_ADMIN, result["value"]["error_code"]
		sign_out(auth_key)
		
		clear(User,Faq)
	end
	
	test "04 should post create action with admin user login" do
		clear(User, Faq)

		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 4
		user.role = 1
		user.save
	
		auth_key = sign_in(user.email, "123456")
		post 'create', :faq => {faq_type: "Type1", question: "question1", answer: "answer1"}, :format => :json, :auth_key => auth_key
		assert_equal ErrorEnum::FAQ_TYPE_ERROR, JSON.parse(@response.body)["value"]["error_code"]
		
		post 'create', :faq => {faq_type: 129, question: "question1", answer: "answer1"}, :format => :json, :auth_key => auth_key
		assert_equal ErrorEnum::FAQ_RANGE_ERROR, JSON.parse(@response.body)["value"]["error_code"]

		post 'create', :faq => {faq_type: 128, answer: "answer1"}, :format => :json, :auth_key => auth_key
		assert_equal ErrorEnum::FAQ_SAVE_FAILED, JSON.parse(@response.body)["value"]["error_code"]
		
		post 'create', :faq => {faq_type: 1, question: "question1", answer: "answer1"}, :format => :json, :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval["question"], "question1"
		faq = Faq.all.first
		assert_equal faq.question, "question1"

		#
		# get index
		#
		post 'create', :faq => {faq_type: 2, question: "question2", answer: "answer2"}, :format => :json, :auth_key => auth_key
		post 'create', :faq => {faq_type: 64, question: "question3", answer: "answer3"}, :format => :json, :auth_key => auth_key
		post 'create', :faq => {faq_type: 128, question: "question4", answer: "answer4"}, :format => :json, :auth_key => auth_key

		# no type, no value
		get 'index', :format => :json, :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval.count, 4

		# with type, no value
		get 'index', :format => :json, :faq_type => 3, :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval.count, 2

		get 'index', :format => :json, :faq_type => 255, :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval.count, 4

		#with type and value
		get 'index', :format => :json, :faq_type => 3, :value => "answer", :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval.count, 2

		get 'index', :format => :json, :faq_type => 3, :value => "answer1", :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval.count, 1

		#paging
		get 'index', :format => :json, :per_page => 2, :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval.count, 2

		get 'index', :format => :json, :per_page => 3, :page=> 2, :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval.count, 1

		sign_out(auth_key)
		
		clear(User,Faq)
	end

	test "05 should post update action which is with admin " do
		clear(User, Faq)

		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 4
		user.role = 1
		user.save
		
		user2 = User.new(email: "test2@example.com", password: Encryption.encrypt_password("123456"))
		user2.status = 4
		user2.role = 1
		user2.save
	
		auth_key = sign_in(user.email, "123456")
		post 'create', :faq => {faq_type: 1, question: "question1", answer: "answer1"}, :format => :json, :auth_key => auth_key
		retval = JSON.parse(@response.body)
		sign_out(auth_key)
		
		auth_key = sign_in(user2.email, "123456")

		faq = Faq.all.first

		post 'update', :id => "123443454354353", :faq => {question: "updated question1"}, :format => :json, :auth_key => auth_key
		assert_equal ErrorEnum::FAQ_NOT_EXIST, JSON.parse(@response.body)["value"]["error_code"]

		post 'update',:id => faq.id.to_s ,  :faq => {faq_type: "Type1", question: "question1", answer: "answer1"}, :format => :json, :auth_key => auth_key
		assert_equal ErrorEnum::FAQ_TYPE_ERROR, JSON.parse(@response.body)["value"]["error_code"]
		
		post 'update',:id => faq.id.to_s,  :faq => {faq_type: 129, question: "question1", answer: "answer1"}, :format => :json, :auth_key => auth_key
		assert_equal ErrorEnum::FAQ_RANGE_ERROR, JSON.parse(@response.body)["value"]["error_code"]

		post 'update', :id => faq.id.to_s, :faq => {question: "updated question1"}, :format => :json, :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval["question"], "updated question1"

		assert_equal Faq.all.count, 1
		faq = Faq.all.first
		assert_equal faq.question, "updated question1"
		assert_equal faq.user, user2

		sign_out(auth_key)

		clear(User,Faq)
	end
	
	test "06 should destroy action which is with admin " do
		clear(User, Faq)
		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 4
		user.role = 1
		user.save
	
		auth_key = sign_in(user.email, "123456")
		post 'create', :faq => {faq_type: 1, question: "question1", answer: "answer1"}, :format => :json, :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]

		post 'destroy', :id => retval["_id"], :format => :json, :auth_key => auth_key
		assert_equal JSON.parse(@response.body)["value"], true
		
		retval = Faq.where(_id: retval["_id"]).first
		assert_equal retval, nil
		sign_out(auth_key)

		clear(User,Faq)
	end
	
end
