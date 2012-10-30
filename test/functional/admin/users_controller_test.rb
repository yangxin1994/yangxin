require 'test_helper'

class Admin::UsersControllerTest < ActionController::TestCase

	test "01 get index" do 
		clear(User)

		get 'index', :format => :json
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::REQUIRE_LOGIN.to_s, result["value"]["error_code"]

		jesse = init_jesse
		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get 'index', :format => :json, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::REQUIRE_ADMIN, result["value"]["error_code"]
		sign_out(auth_key)

		clear(User)
		admin = init_admin
		auth_key = sign_in(admin.email, Encryption.decrypt_password(admin.password))
		get 'index', :format => :json, :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval[0]["_id"], admin.id.to_s
		assert_equal retval[0]["password"], nil
		sign_out(auth_key)
		clear(User)
	end

	test "02 should be show user " do 
		clear(User)
		admin = init_admin

		auth_key = sign_in(admin.email, Encryption.decrypt_password(admin.password))
		get 'show', :format => :json, :id => admin.id.to_s, :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval["_id"], admin.id.to_s

		sign_out(auth_key)

		clear(User)
	end

	test "03 should be update user " do 
		clear(User)

		admin = init_admin
		assert_equal User.all.count, 1
		auth_key = sign_in(admin.email, Encryption.decrypt_password(admin.password))
		put 'update', :format => :json, :id => admin.id.to_s, :user => {phone: "12345678900"}, :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval, true

		sign_out(auth_key)

		clear(User)
	end

	test '04 should operate user to black' do 
		clear(User)

		#create admin user
		admin = init_admin
		#create some normal user
		jesse = init_jesse

		auth_key = sign_in(admin.email, Encryption.decrypt_password(admin.password))
		# ***************
		# change jesse to black 
		post 'set_color', :id => jesse.id.to_s, :color => -1, :format => :json, :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval["_id"], jesse.id.to_s
		assert_equal retval["color"], -1

		return

		get 'blacks', :format => :json, :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval.count, 1

		# change jesse to normal
		post 'set_color', :id => jesse.id.to_s, :color => 0, :format => :json, :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval["_id"], jesse.id.to_s
		assert_equal retval["color"], 0

		sign_out(auth_key)

		clear(User)
	end

	test "06 should change password to system password" do 
		clear(User)

		#create admin user
		admin = init_admin
		#create some normal user
		jesse = init_jesse

		auth_key = sign_in(admin.email, Encryption.decrypt_password(admin.password))

		get 'system_pwd', :id => jesse.id.to_s, :format => :json, :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval["_id"], jesse.id.to_s
		assert_not_equal retval["password"], Encryption.encrypt_password(jesse.password)
		assert_not_equal User.find(jesse.id.to_s).password, Encryption.encrypt_password(jesse.password)
		
		sign_out(auth_key)

		clear(User)
	end

end