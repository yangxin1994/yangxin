require 'test_helper'

class FeedbacksControllerTest < ActionController::TestCase

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
		assert_equal JSON.parse(@response.body), []

		sign_out

		clear(Feedback, User)
	end
	
	test "02 should post create action" do
		clear(User, Feedback)
		# create feedback with login user
		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 0
		user.save
		
		sign_in(user.email, "123456")

		post 'create', :feedback => {feedback_type: "Type1", title: "title1", content: "content1"}, :format => :json
		retval = @response.body.to_i
		assert_equal retval, ErrorEnum::FEEDBACK_TYPE_ERROR
		
		post 'create', :feedback => {feedback_type: 129, title: "title1", content: "content1"}, :format => :json
		retval = @response.body.to_i
		assert_equal retval, ErrorEnum::FEEDBACK_RANGE_ERROR

		post 'create', :feedback => {feedback_type: 1, title: "title1", content: "content1"}, :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval["title"], "title1"
		feedback = Feedback.all.first
		assert_equal feedback.title, "title1"
		assert_equal feedback.question_user, user

		post 'create', :feedback => {content: "content1"}, :format => :json
		retval = @response.body.to_i
		assert_equal retval, ErrorEnum::FEEDBACK_SAVE_FAILED

		#
		# get index
		#
		post 'create', :feedback => {feedback_type: 2, title: "title2", content: "content2"}, :format => :json
		post 'create', :feedback => {feedback_type: 64, title: "title3", content: "content3"}, :format => :json
		post 'create', :feedback => {feedback_type: 128, title: "title4", content: "content4"}, :format => :json

		# no type, no value
		get 'index', :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 4

		# with type, no value
		get 'index', :format => :json, :feedback_type => 3
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 2

		get 'index', :format => :json, :feedback_type => 255
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 4

		#with type and value
		get 'index', :format => :json, :feedback_type => 3, :value => "content"
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 2

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
		
		clear(User,Feedback)
	end

	test "03 should post update action which is with admin" do
		clear(User, Feedback)

		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 0
		user.save
		
		user2 = User.new(email: "test2@example.com", password: Encryption.encrypt_password("123456"))
		user2.status = 2
		user2.role = 0
		user2.save
	
		sign_in(user.email, "123456")
		post 'create', :feedback => {feedback_type: 1, title: "title1", content: "content1"}, :format => :json
		retval = JSON.parse(@response.body)
		sign_out
		
		sign_in(user2.email, "123456")

		feedback = Feedback.all.first

		post 'update', :id => "123443454354353", :feedback => {title: "updated title1"}, :format => :json
		retval = @response.body.to_i
		assert_equal retval, ErrorEnum::FEEDBACK_NOT_EXIST

		post 'update',:id => feedback.id.to_s ,  :feedback => {feedback_type: "Type1", title: "title1", content: "content1"}, :format => :json
		retval = @response.body.to_i
		assert_equal retval, ErrorEnum::FEEDBACK_TYPE_ERROR
		
		post 'update',:id => feedback.id.to_s,  :feedback => {feedback_type: 129, title: "title1", content: "content1"}, :format => :json
		retval = @response.body.to_i
		assert_equal retval, ErrorEnum::FEEDBACK_RANGE_ERROR

		post 'update',:id => feedback.id.to_s,  :feedback => {feedback_type: 4, title: "title1", content: "content1"}, :format => :json
		retval = @response.body.to_i
		assert_equal retval, ErrorEnum::FEEDBACK_NOT_CREATOR

		sign_out

		sign_in(user.email, "123456")
		post 'update', :id => feedback.id.to_s, :feedback => {title: "updated title1"}, :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval["title"], "updated title1"

		assert_equal Feedback.all.count, 1
		feedback = Feedback.all.first
		assert_equal feedback.title, "updated title1"
		assert_equal feedback.question_user, user

		sign_out

		clear(User,Feedback)
	end
	
	test "04 should destroy action which is with admin" do
		clear(User, Feedback)
		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 0
		user.save
	
		sign_in(user.email, "123456")
		post 'create', :feedback => {feedback_type: 1, title: "title1", content: "content1"}, :format => :json
		retval = JSON.parse(@response.body)

		post 'destroy', :id => retval["_id"], :format => :json
		assert_equal @response.body, "true"
		
		retval = Feedback.where(_id: retval["_id"]).first
		assert_equal retval, nil
		sign_out

		clear(User,Feedback)
	end

end
