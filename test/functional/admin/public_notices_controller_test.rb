require 'test_helper'

class Admin::PublicNoticesControllerTest < ActionController::TestCase

	test "01 should get index action and no public_notice record" do
		clear(User, PublicNotice)
		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 4
		user.role = 1
		user.save
	
		auth_key = sign_in(user.email, "123456")
		get 'index', :format => :json, :auth_key => auth_key
		assert_equal JSON.parse(@response.body)['value'], []		
		sign_out(auth_key)
		
		clear(User,PublicNotice)
	end

	test "02 should post create action which is without login" do
		clear(User, PublicNotice)
	
		post 'create', :public_notice => {public_notice_type: 1, title: "title1", content: "content1"}, :format => :json
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::REQUIRE_LOGIN.to_s, result["value"]["error_code"]
		
		clear(User,PublicNotice)
	end
	
	test "03 should post create action with login, but not admin user" do
		clear(User, PublicNotice)
		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 4
		user.role = 0
		user.save
	
		auth_key = sign_in(user.email, "123456")
		post 'create', :public_notice => {public_notice_type: 1, title: "title1", content: "content1"}, :format => :json, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::REQUIRE_ADMIN.to_s, result["value"]["error_code"]
		sign_out(auth_key)
		
		clear(User,PublicNotice)
	end
	
	test "04 should post create action with admin user login" do
		clear(User, PublicNotice)

		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 4
		user.role = 1
		user.save
	
		auth_key = sign_in(user.email, "123456")
		post 'create', :public_notice => {public_notice_type: "Type1", title: "title1", content: "content1"}, :format => :json, :auth_key => auth_key
		assert_equal ErrorEnum::PUBLIC_NOTICE_TYPE_ERROR, JSON.parse(@response.body)["value"]
		
		post 'create', :public_notice => {public_notice_type: 129, title: "title1", content: "content1"}, :format => :json, :auth_key => auth_key
		assert_equal ErrorEnum::PUBLIC_NOTICE_RANGE_ERROR, JSON.parse(@response.body)["value"]
		
		post 'create', :public_notice => {public_notice_type: 1, title: "title1", content: "content1"}, :format => :json, :auth_key => auth_key
		retval = JSON.parse(@response.body)
		assert_equal retval["value"]["title"], "title1"
		public_notice = PublicNotice.all.first
		assert_equal public_notice.title, "title1"

		#
		# get index
		#
		post 'create', :public_notice => {public_notice_type: 2, title: "title2", content: "content2"}, :format => :json, :auth_key => auth_key
		post 'create', :public_notice => {public_notice_type: 64, title: "title3", content: "content3"}, :format => :json, :auth_key => auth_key
		post 'create', :public_notice => {public_notice_type: 128, title: "title4", content: "content4"}, :format => :json, :auth_key => auth_key

		# no type, no value
		get 'index', :format => :json, :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval.count, 4

		# with type, no value
		get 'index', :format => :json, :public_notice_type => 3, :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval.count, 2

		get 'index', :format => :json, :public_notice_type => 255, :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval.count, 4

		#with type and value
		get 'index', :format => :json, :public_notice_type => 3, :value => "content", :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval.count, 2

		get 'index', :format => :json, :public_notice_type => 3, :value => "content1", :auth_key => auth_key
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
		
		clear(User,PublicNotice)
	end

	test "05 should post update action which is with admin " do
		clear(User, PublicNotice)

		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 4
		user.role = 1
		user.save
		
		user2 = User.new(email: "test2@example.com", password: Encryption.encrypt_password("123456"))
		user2.status = 4
		user2.role = 1
		user2.save
	
		auth_key = sign_in(user.email, "123456")
		post 'create', :public_notice => {public_notice_type: 1, title: "title1", content: "content1"}, :format => :json, :auth_key => auth_key
		retval = JSON.parse(@response.body)
		sign_out(auth_key)
		
		auth_key = sign_in(user2.email, "123456")

		public_notice = PublicNotice.all.first

		post 'update', :id => "123443454354353", :public_notice => {title: "updated title1"}, :format => :json, :auth_key => auth_key
		assert_equal ErrorEnum::PUBLIC_NOTICE_NOT_EXIST, JSON.parse(@response.body)["value"]

		post 'update',:id => public_notice.id.to_s ,  :public_notice => {public_notice_type: "Type1", title: "title1", content: "content1"}, :format => :json, :auth_key => auth_key
		assert_equal ErrorEnum::PUBLIC_NOTICE_TYPE_ERROR, JSON.parse(@response.body)["value"]
		
		post 'update',:id => public_notice.id.to_s,  :public_notice => {public_notice_type: 129, title: "title1", content: "content1"}, :format => :json, :auth_key => auth_key
		assert_equal ErrorEnum::PUBLIC_NOTICE_RANGE_ERROR, JSON.parse(@response.body)["value"]

		post 'update', :id => public_notice.id.to_s, :public_notice => {title: "updated title1"}, :format => :json, :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval["title"], "updated title1"

		assert_equal PublicNotice.all.count, 1
		public_notice = PublicNotice.all.first
		assert_equal public_notice.title, "updated title1"
		assert_equal public_notice.user, user2

		sign_out(auth_key)

		clear(User,PublicNotice)
	end
	
	test "06 should destroy action which is with admin " do
		clear(User, PublicNotice)
		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 4
		user.role = 1
		user.save
	
		auth_key = sign_in(user.email, "123456")
		post 'create', :public_notice => {public_notice_type: 1, title: "title1", content: "content1"}, :format => :json, :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]

		post 'destroy', :id => retval["_id"], :format => :json, :auth_key => auth_key
		assert_equal JSON.parse(@response.body)["value"], true
		
		retval = PublicNotice.where(_id: retval["_id"]).first
		assert_equal retval, nil
		sign_out(auth_key)

		clear(User,PublicNotice)
	end
end
