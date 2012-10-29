require 'test_helper'

class Admin::SystemUsersControllerTest < ActionController::TestCase
=begin
	test "01 get index" do 
		clear(User)

		get 'index', :format => :json
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::REQUIRE_LOGIN.to_s, result["value"]["error_code"]

		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 4
		user.role = 0
		user.save
	
		auth_key = sign_in(user.email, "123456")
		get 'index', :format => :json, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::REQUIRE_ADMIN.to_s, result["value"]["error_code"]
		sign_out(auth_key)

		user = User.new(email: "test2@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 4
		user.role = 1
		user.save

		auth_key = sign_in(user.email, "123456")
		get 'index', :format => :json, :auth_key => auth_key
		assert_equal JSON.parse(@response.body)["value"], []
		sign_out(auth_key)

		clear(User)
	end

	test "02 post create" do 
		clear(User)

		post 'create', :system_user => {username: "zhangsan", password: "123456", true_name:'zhangsan'}, :format => :json
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::REQUIRE_LOGIN.to_s, result["value"]["error_code"]

		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 4
		user.role = 0
		user.save
	
		auth_key = sign_in(user.email, "123456")
		post 'create', :system_user => {username: "zhangsan", password: "123456", true_name: 'zhangsan'}, :format => :json, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::REQUIRE_ADMIN.to_s, result["value"]["error_code"]
		sign_out(auth_key)

		user = User.new(email: "test2@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 4
		user.role = 1
		user.save
	
		auth_key = sign_in(user.email, "123456")		
		post 'create', :system_user => {email: "1@example.com", username: "zhangsan", password: "123456", true_name:'zhangsan'}, :format => :json, :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval["username"], "zhangsan"

		sleep(1)

		post 'create', :system_user => {email: "2@example.com", username: "lisi", password: "123456", system_user_type: 2, true_name:'lisi'}, :format => :json, :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval["username"], "lisi"

		post 'create', :system_user => {email: "3@example.com", username: "lisi", password: "123456", system_user_type: 2, true_name:'lisi'}, :format => :json, :auth_key => auth_key
		assert_equal ErrorEnum::USERNAME_EXIST, JSON.parse(@response.body)["value"]["error_code"]

		post 'create', :system_user => {email: "test@example.com", password: "123456", system_user_type: 2, true_name:'lisi'}, :format => :json, :auth_key => auth_key
		assert_equal ErrorEnum::EMAIL_EXIST, JSON.parse(@response.body)["value"]["error_code"]

		post 'create', :system_user => {password: "123456", system_user_type: 2, true_name:'lisi'}, :format => :json, :auth_key => auth_key
		assert_equal ErrorEnum::SYSTEM_USER_MUST_EMAIL_OR_USERNAME, JSON.parse(@response.body)["value"]["error_code"]

		assert_equal SystemUser.all.count, 2
		# get index
		get 'index', :format => :json, :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval.count, 2

		get 'index', :format => :json, :system_user_type => 1, :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval.count, 1
		assert_equal retval[0]["username"], "zhangsan"

		get 'index', :format => :json, :system_user_type => 2, :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval.count, 1
		assert_equal retval[0]["username"], "lisi"

		get 'index', :format => :json, :system_user_type => 15, :lock => true, :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval.count, 0

		get 'index', :format => :json, :system_user_type => 15, :lock => false, :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval.count, 2
		assert_equal retval[0]["true_name"], "lisi"
		assert_equal retval[1]["true_name"], "zhangsan"

		#paging
		get 'index', :format => :json, :page => 2, :per_page => 1, :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval.count, 1

		sign_out(auth_key)

		clear(User)
	end

	test "03 post update" do
		clear(User)

		post 'update',:id => "5004bffb6c6eea1204000009",  :system_user => {username: "zhangsan", password: "123456", true_name:'zhangsan'}, :format => :json
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::REQUIRE_LOGIN.to_s, result["value"]["error_code"]

		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 4
		user.role = 0
		user.save
	
		auth_key = sign_in(user.email, "123456")
		post 'update',:id => "5004bffb6c6eea1204000009",  :system_user => {username: "zhangsan", password: "123456"}, :format => :json, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::REQUIRE_ADMIN.to_s, result["value"]["error_code"]
		sign_out(auth_key)

		return

		user = User.new(email: "test2@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 4
		user.role = 1
		user.save
	
		auth_key = sign_in(user.email, "123456")	
		#create new system user
		post 'create', :system_user => {email: "oop@example.com", username: "zhangsan", password: "123456", true_name:'zhangsan'}, :format => :json, :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval["username"], "zhangsan"

		post 'update',:id => retval["_id"], :system_user => {username: "zhangsan2", true_name: "test", password: "1234567"}, :format => :json, :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval["username"], "zhangsan" # should do not update username attr.
		assert_equal retval["true_name"], "test"

		post 'update',:id => retval["_id"], :system_user => {email: "test2@example.com", true_name: "test", password: "1234567"}, :format => :json, :auth_key => auth_key
		assert_equal ErrorEnum::EMAIL_EXIST, JSON.parse(@response.body)["value"]["error_code"]

		#create new system user
		post 'create', :system_user => {email: "oop2@example.com", password: "123456", true_name:'zhangsan'}, :format => :json, :auth_key => auth_key
		retval = JSON.parse(@response.body)
		assert_equal retval["true_name"], "zhangsan"

		system_user = SystemUser.find(retval["_id"])
		assert_equal system_user.password, Encryption.encrypt_password("123456")

		post 'update',:id => retval["_id"], :system_user => {email: "", true_name: "test", password: "1234567"}, :format => :json, :auth_key => auth_key
		assert_equal ErrorEnum::SYSTEM_USER_MUST_EMAIL_OR_USERNAME, JSON.parse(@response.body)["value"]["error_code"]

		sign_out(auth_key)

		clear(User)
	end

	test "04 post lock" do 
		clear(User)

		post 'lock', :id => "5004bffb6c6eea1204000009", :format => :json
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::REQUIRE_LOGIN.to_s, result["value"]["error_code"]

		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 4
		user.role = 0
		user.save
	
		auth_key = sign_in(user.email, "123456")
		post 'lock', :id => "5004bffb6c6eea1204000009", :format => :json, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::REQUIRE_ADMIN.to_s, result["value"]["error_code"]
		sign_out(auth_key)

		user = User.new(email: "test2@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 4
		user.role = 1
		user.save
	
		auth_key = sign_in(user.email, "123456")		
		post 'create', :system_user => {email: "11@example.com", username: "zhangsan", password: "123456", true_name:'zhangsan'}, :format => :json, :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval["username"], "zhangsan"

		post 'lock',:id => retval["_id"], :format => :json, :auth_key => auth_key
		retval = JSON.parse(@response.body)
		assert_equal retval["value"], true

		sign_out(auth_key)

		clear(User)
	end

	test "05 post unlock" do
		clear(User)

		post 'unlock', :id => "5004bffb6c6eea1204000009", :format => :json
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::REQUIRE_LOGIN.to_s, result["value"]["error_code"]

		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 4
		user.role = 0
		user.save
	
		auth_key = sign_in(user.email, "123456")
		post 'unlock', :id => "5004bffb6c6eea1204000009", :format => :json, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::REQUIRE_ADMIN.to_s, result["value"]["error_code"]
		sign_out(auth_key)

		user = User.new(email: "test2@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 4
		user.role = 1
		user.save
	
		auth_key = sign_in(user.email, "123456")		
		post 'create', :system_user => {email: "12@example.com", username: "zhangsan", password: "123456", true_name:'zhangsan', lock: true}, :format => :json, :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval["username"], "zhangsan"
		assert_equal retval["lock"], true

		post 'unlock',:id => retval["_id"], :format => :json, :auth_key => auth_key
		retval = JSON.parse(@response.body)
		assert_equal retval["value"], true

		sign_out(auth_key)

		clear(User)
	end
=end
end
