# coding: utf-8

require 'test_helper'

class Admin::FeedbacksControllerTest < ActionController::TestCase

	test "01 should get index action and no feedback record" do
		clear(Feedback, User)

		assert_equal User.all.count, 0

		get 'index', :format => :json
		assert_equal @response.body.to_i, ErrorEnum::REQUIRE_LOGIN

		assert_equal User.all.count, 1

		clear(Feedback, User)

		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 0
		user.save

		assert_equal User.all.first, user

		sign_in(user.email, "123456")
		get 'index', :format => :json
		assert_equal @response.body.to_i, ErrorEnum::REQUIRE_ADMIN
		sign_out

		user1 = User.new(email: "test2@example.com", password: Encryption.encrypt_password("123456"))
		user1.status = 2
		user1.role = 1
		user1.save

		sign_in(user1.email, "123456")

		get 'index', :format => :json
		assert_equal JSON.parse(@response.body), []

		assert_equal Feedback.all.count, 0
		Feedback.create_feedback({feedback_type: 1, title: "title1", content: "content1"}, user)
		Feedback.create_feedback({feedback_type: 1, title: "title2", content: "content2"}, user)
		Feedback.create_feedback({feedback_type: 2, title: "title3", content: "content3"}, user)
		Feedback.create_feedback({feedback_type: 8, title: "title4", content: "content4"}, user)

		assert_equal Feedback.all.count, 4

		# no type, no value
		get 'index', :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 4

		# with type, no value
		get 'index', :format => :json, :feedback_type => 3
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 3

		get 'index', :format => :json, :feedback_type => 255
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 4

		#with type and value
		get 'index', :format => :json, :feedback_type => 3, :value => "content"
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 3

		get 'index', :format => :json, :feedback_type => 3, :value => "content1"
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 1		

		#with type and answer
		get 'index', :format => :json, :feedback_type => 255, :answer => false
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 4

		fb = Feedback.all.first
		fb.is_answer = true
		assert_equal fb.save, true
		assert_equal Feedback.all.first.is_answer, true

		get 'index', :format => :json, :feedback_type => 255, :answer => true
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 1

		get 'index', :format => :json, :feedback_type => 255, :answer => false
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 3

		#paging
		get 'index', :format => :json, :per_page => 2, :feedback_type => 255
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 2

		get 'index', :format => :json, :per_page => 3, :page=> 2, :feedback_type => 255
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 1

		sign_out

		clear(Feedback, User)
	end
	
	test "02 should destroy action which is with admin" do
		clear(User, Feedback)

		#create feedback
		assert_equal Feedback.all.count, 0
		f = Feedback.new(feedback_type: 1, title: "title1", content: "content1")
		assert_equal f.save, true
		assert_equal Feedback.all.count, 1

		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 1
		user.save
	
		sign_in(user.email, "123456")

		post 'destroy', :id => f.id.to_s , :format => :json
		assert_equal @response.body, "true"
		
		retval = Feedback.where(_id: f.id).first
		assert_equal retval, nil
		sign_out

		clear(User,Feedback)
	end
	
	test "03 should post reply method" do 
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
		sign_in(user2.email, Encryption.decrypt_password(user2.password))
		post "reply",:id => f.id.to_s, :message_content => "reply feedback", :format => :json
		assert_equal Message.all.count, 1 #reply successfully.

		retval = JSON.parse(@response.body)
		assert_equal retval["content"], "reply feedback"
		assert_equal retval["title"], "反馈意见回复:"+ f.title.to_s

		sign_out

		clear(User, Feedback, Message)
	end

end
