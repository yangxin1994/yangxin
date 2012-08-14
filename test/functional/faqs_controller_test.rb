require 'test_helper'

class FaqsControllerTest < ActionController::TestCase

	test "01 should get index action " do
		clear(Faq)

		get 'index', :format => :json
		assert_equal JSON.parse(@response.body), []

		#create some faqs for condition index
		f1 = Faq.new(faq_type: 2, question: "question1", answer: "answer1")
		assert_equal f1.save, true
		f2 = Faq.new(faq_type: 4, question: "question2", answer: "answer2")
		assert_equal f2.save, true
		f3 = Faq.new(faq_type: 8, question: "question3", answer: "answer3")
		assert_equal f3.save, true
		f4 = Faq.new(faq_type: 16, question: "question4", answer: "answer4")
		assert_equal f4.save, true

		assert_equal Faq.all.count, 4

		# no type, no value
		get 'index', :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 4

		# with type, no value
		get 'index', :format => :json, :faq_type => 6
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 2

		get 'index', :format => :json, :faq_type => 255
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 4

		#with type and value
		get 'index', :format => :json, :faq_type => 6, :value => "answer"
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 2

		get 'index', :format => :json, :faq_type => 6, :value => "answer1"
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 1

		post 'destroy', :id => retval["_id"], :format => :json
		assert_equal @response.body, "true"
		
		retval = Faq.where(_id: retval["_id"]).first
		assert_equal retval, nil
		sign_out

		clear(User,Faq)
	end

	
	test "my test" do
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
		retval = JSON.parse(@response.body)
		assert_equal retval["error"], ErrorEnum::ARG_ERROR
		sign_out
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
		#paging
		get 'index', :format => :json, :per_page => 2
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 2

		get 'index', :format => :json, :per_page => 3, :page=> 2
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 1

		clear(Faq)
	end

	test "02 should get show action" do
		clear(Faq)

		f = Faq.new(faq_type: 2, question: "question2", answer: "answer2")
		assert_equal f.save, true

		assert_equal Faq.all.count, 1
		get "show", :format => :json, :id => f.id.to_s
		retval = JSON.parse(response.body)

		assert_equal retval["_id"], f.id.to_s
		assert_equal retval["faq_type"], 2
		assert_equal retval["question"], "question2"

		clear(Faq)
	end
	
end
