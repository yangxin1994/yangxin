require 'test_helper'

class FeedbacksControllerTest < ActionController::TestCase

	test "01 should get index action and no feedback record" do
		clear(Feedback)
		get 'index', :format => :json
		assert_equal JSON.parse(@response.body), []		
		clear(Feedback)
	end

	test "02 should post create action which is without login" do
		clear(Feedback)
	
		post 'create', :feedback => {feedback_type: 1, title: "title1", content: "content1"}, :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval["title"], "title1"
		
		clear(Feedback)
	end
	
	test "03 should post create action with login" do
		clear(User, Feedback)
		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 0
		user.save
	
		sign_in(user.email, Encryption.decrypt_password(user.password))
		post 'create', :feedback => {feedback_type: 1, title: "title1", content: "content1"}, :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval["title"], "title1"
		sign_out
		
		clear(User,Feedback)
	end

	test "04 should post update action " do
		clear(User, Feedback)
		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 1
		user.save
	
		sign_in(user.email, Encryption.decrypt_password(user.password))
		post 'create', :feedback => {feedback_type: 1, title: "title1", content: "content1"}, :format => :json
		retval = JSON.parse(@response.body)
		sign_out
		
		sign_in(user.email, Encryption.decrypt_password(user.password))
		post 'update', :id => retval["_id"], :feedback => {title: "updated title1"}, :format => :json
		
		retval = Feedback.find(retval["_id"])
		assert_equal retval["title"], "updated title1"
		sign_out

		clear(User,Feedback)
	end
	
	test "05 should destroy action which is with admin " do
		clear(User, Feedback)
		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 1
		user.save
	
		sign_in(user.email, Encryption.decrypt_password(user.password))
		post 'create', :feedback => {feedback_type: 1, title: "title1", content: "content1"}, :format => :json
		retval = JSON.parse(@response.body)

		post 'destroy', :id => retval["_id"], :format => :json
		
		retval = Feedback.where(_id: retval["_id"]).first
		assert_equal retval, nil
		sign_out

		clear(User,Feedback)
	end

	test "07 should get condition action" do
	
		clear(User, Feedback)
		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 1
		user.save
	
		sign_in(user.email, Encryption.decrypt_password(user.password))
		post 'create', :feedback => {feedback_type: 1, title: "title1", content: "content1"}, :format => :json
		post 'create', :feedback => {feedback_type: 2, title: "title2", content: "content1"}, :format => :json
		post 'create', :feedback => {feedback_type: 4, title: "title4", content: "content1"}, :format => :json
		
		get 'condition', :type => 1, :value => "user", :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 0
		
		get 'condition', :type => 7, :value => "content1", :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 3

		get 'condition', :type => 0, :value => "title1", :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 0

		get 'condition', :type => 0, :value => "content1", :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 0
		
		sign_out
		clear(User, Feedback)
	end

	test "08 should get types action" do 
		clear(User, Feedback)

		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 1
		user.save

		sign_in(user.email, Encryption.decrypt_password(user.password))
		post 'create', :feedback => {feedback_type: 1, title: "title1", content: "content1"}, :format => :json
		post 'create', :feedback => {feedback_type: 2, title: "title2", content: "content1"}, :format => :json
		post 'create', :feedback => {feedback_type: 4, title: "title4", content: "content1"}, :format => :json

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

		clear(User, Feedback)
	end
	
=begin
	test "09 should post reply method" do 
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
		
		sign_in(user2.email, Encryption.decrypt_password(user2.password))
		post "#{f.id.to_s/reply}", :message_content => "reply feedback", :format => :json
	
		m = Message.where(question_user: user, answer_user: user2).first
		assert_equal m.content, "reply feedback"		
		
		sign_out
		clear(User, Feedback, Message)
	end
=end

end
