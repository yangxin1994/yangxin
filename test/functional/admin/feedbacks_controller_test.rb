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

		user = User.new(email: "test2@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 1
		user.save

		sign_in(user.email, "123456")
		get 'index', :format => :json
		assert_equal JSON.parse(@response.body), []
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
	
=begin
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
		
		f = Feedback.create(feedback_type: 1, title: "title1", content: "content1")
		f.title_user = user 
		f.save
		
		sign_in(user2.email, Encryption.decrypt_password(user2.password))
		post "#{f.id.to_s/reply}", :message_content => "reply feedback", :format => :json
	
		m = Message.where(title_user: user, content_user: user2).first
		assert_equal m.content, "reply feedback"		
		
		sign_out
		clear(User, Feedback, Message)
	end
=end

end
