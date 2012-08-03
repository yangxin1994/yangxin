require 'test_helper'

class SystemUsersControllerTest < ActionController::TestCase

	test "01 get index" do 
		clear(User)

		get 'index', :format => :json
		retval = @response.body.to_i
		assert_equal retval, ErrorEnum::REQUIRE_LOGIN

		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 0
		user.save
	
		sign_in(user.email, "123456")
		get 'index', :format => :json
		retval = @response.body.to_i
		assert_equal retval, ErrorEnum::REQUIRE_ADMIN
		sign_out

		user = User.new(email: "test2@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 1
		user.save

		sign_in(user.email, "123456")
		get 'index', :format => :json
		assert_equal JSON.parse(@response.body), []
		sign_out

		clear(User)
	end

	test "02 post create" do 
		clear(User)

		post 'create', :system_user => {username: "zhangsan", password: "123456", true_name:'zhangsan'}, :format => :json
		retval = @response.body.to_i
		assert_equal retval, ErrorEnum::REQUIRE_LOGIN

		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 0
		user.save
	
		sign_in(user.email, "123456")
		post 'create', :system_user => {username: "zhangsan", password: "123456", true_name: 'zhangsan'}, :format => :json
		retval = @response.body.to_i
		assert_equal retval, ErrorEnum::REQUIRE_ADMIN
		sign_out

		user = User.new(email: "test2@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 1
		user.save
	
		sign_in(user.email, "123456")		
		post 'create', :system_user => {username: "zhangsan", password: "123456", true_name:'zhangsan'}, :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval["username"], "zhangsan"

		sleep(1)

		post 'create', :system_user => {username: "lisi", password: "123456", system_user_type: 2, true_name:'lisi'}, :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval["username"], "lisi"

		post 'create', :system_user => {username: "lisi", password: "123456", system_user_type: 2, true_name:'lisi'}, :format => :json
		retval = @response.body.to_i
		assert_equal retval, ErrorEnum::USERNAME_EXIST

		post 'create', :system_user => {email: "test@example.com", password: "123456", system_user_type: 2, true_name:'lisi'}, :format => :json
		retval = @response.body.to_i
		assert_equal retval, ErrorEnum::EMAIL_EXIST

		post 'create', :system_user => {password: "123456", system_user_type: 2, true_name:'lisi'}, :format => :json
		retval = @response.body.to_i
		assert_equal retval, ErrorEnum::SYSTEM_USER_MUST_EMAIL_OR_USERNAME

		post 'create', :system_user => {email: "test4@example.com", system_user_type: 2, true_name:'lisi'}, :format => :json
		retval = @response.body.to_i
		assert_equal retval, ErrorEnum::SYSTEM_USER_SAVE_FAILED

		assert_equal SystemUser.all.count, 2
		# get index
		get 'index', :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 2

		get 'index', :format => :json, :system_user_type => 1
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 1
		assert_equal retval[0]["username"], "zhangsan"

		get 'index', :format => :json, :system_user_type => 2
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 1
		assert_equal retval[0]["username"], "lisi"

		get 'index', :format => :json, :system_user_type => 15, :lock => true
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 0

		get 'index', :format => :json, :system_user_type => 15, :lock => false
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 2
		assert_equal retval[0]["true_name"], "lisi"
		assert_equal retval[1]["true_name"], "zhangsan"

		#paging
		get 'index', :format => :json, :page => 2, :per_page => 1
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 1

		sign_out

		clear(User)
	end

	test "03 post update" do
		clear(User)

		post 'update',:id => "5004bffb6c6eea1204000009",  :system_user => {username: "zhangsan", password: "123456", true_name:'zhangsan'}, :format => :json
		retval = @response.body.to_i
		assert_equal retval, ErrorEnum::REQUIRE_LOGIN

		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 0
		user.save
	
		sign_in(user.email, "123456")
		post 'update',:id => "5004bffb6c6eea1204000009",  :system_user => {username: "zhangsan", password: "123456"}, :format => :json
		retval = @response.body.to_i
		assert_equal retval, ErrorEnum::REQUIRE_ADMIN
		sign_out

		user = User.new(email: "test2@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 1
		user.save
	
		sign_in(user.email, "123456")	
		#create new system user
		post 'create', :system_user => {email: "oop@example.com", username: "zhangsan", password: "123456", true_name:'zhangsan'}, :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval["username"], "zhangsan"

		post 'update',:id => retval["_id"], :system_user => {username: "zhangsan2", true_name: "test", password: "1234567"}, :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval["username"], "zhangsan" # should do not update username attr.
		assert_equal retval["true_name"], "test"

		post 'update',:id => retval["_id"], :system_user => {email: "test2@example.com", true_name: "test", password: "1234567"}, :format => :json
		retval = @response.body.to_i
		assert_equal retval, ErrorEnum::EMAIL_EXIST

		#create new system user
		post 'create', :system_user => {email: "oop2@example.com", password: "123456", true_name:'zhangsan'}, :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval["true_name"], "zhangsan"

		system_user = SystemUser.find(retval["_id"])
		assert_equal system_user.password, Encryption.encrypt_password("123456")

		post 'update',:id => retval["_id"], :system_user => {email: "", true_name: "test", password: "1234567"}, :format => :json
		retval = @response.body.to_i
		assert_equal retval, ErrorEnum::SYSTEM_USER_MUST_EMAIL_OR_USERNAME

		sign_out

		clear(User)
	end

	test "04 post lock" do 
		clear(User)

		post 'lock', :id => "5004bffb6c6eea1204000009", :format => :json
		retval = @response.body.to_i
		assert_equal retval, ErrorEnum::REQUIRE_LOGIN

		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 0
		user.save
	
		sign_in(user.email, "123456")
		post 'lock', :id => "5004bffb6c6eea1204000009", :format => :json
		retval = @response.body.to_i
		assert_equal retval, ErrorEnum::REQUIRE_ADMIN
		sign_out

		user = User.new(email: "test2@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 1
		user.save
	
		sign_in(user.email, "123456")		
		post 'create', :system_user => {username: "zhangsan", password: "123456", true_name:'zhangsan'}, :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval["username"], "zhangsan"

		post 'lock',:id => retval["_id"], :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval["lock"], true

		system_user = SystemUser.find(retval["_id"])
		assert_equal system_user.lock, true

		sign_out

		clear(User)
	end

	test "05 post unlock" do
		clear(User)

		post 'unlock', :id => "5004bffb6c6eea1204000009", :format => :json
		retval = @response.body.to_i
		assert_equal retval, ErrorEnum::REQUIRE_LOGIN

		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 0
		user.save
	
		sign_in(user.email, "123456")
		post 'unlock', :id => "5004bffb6c6eea1204000009", :format => :json
		retval = @response.body.to_i
		assert_equal retval, ErrorEnum::REQUIRE_ADMIN
		sign_out

		user = User.new(email: "test2@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 1
		user.save
	
		sign_in(user.email, "123456")		
		post 'create', :system_user => {username: "zhangsan", password: "123456", true_name:'zhangsan', lock: true}, :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval["username"], "zhangsan"
		assert_equal retval["lock"], true

		post 'unlock',:id => retval["_id"], :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval["lock"], false

		system_user = SystemUser.find(retval["_id"])
		assert_equal system_user.lock, false

		sign_out

		clear(User)
	end

end