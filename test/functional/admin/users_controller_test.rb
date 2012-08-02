require 'test_helper'

class Admin::UsersControllerTest < ActionController::TestCase

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

		clear(User)

		user = User.new(email: "test2@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 1
		user.save

		sign_in(user.email, "123456")
		get 'index', :format => :json
		assert_equal JSON.parse(@response.body)[0]["_id"], user.id.to_s
		sign_out

		clear(User)
	end

	test "02 should be show user " do 
		clear(User)

		user = User.new(email: "test2@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 1
		user.save

		sign_in(user.email, "123456")

		get 'show', :format => :json, :id => user.id.to_s
		retval = JSON.parse(@response.body)
		assert_equal retval["_id"], user.id.to_s

		sign_out

		clear(User)
	end

	test "03 should be update user " do 
		clear(User)

		user = User.new(email: "test2@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 1
		user.save

		assert_equal User.all.count, 1

		sign_in(user.email, "123456")
		
		put 'update', :format => :json, :id => user.id.to_s, :user => {phone: "12345678900"}
		retval = JSON.parse(@response.body)
		assert_equal retval["_id"], user.id.to_s
		assert_equal retval["phone"], "12345678900"
		#assert_equal User.all.count, 1
		assert_equal User.all.first.phone, "12345678900"

		sign_out

		clear(User)
	end

	test '04 should operate user to black' do 
		clear(User)

		#create admin user
		admin = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		admin.status = 2 
		admin.role = 1
		admin.save

		#create some normal user
		user1 = User.create(email: "test1@example.com", password: Encryption.encrypt_password("123456"))

		assert_equal User.all.count, 2
		assert_equal User.where(role: 1).count, 1
		assert_equal User.where(role: 0).count, 1

		sign_in(admin.email, "123456")

		# ***************
		# change user1 to black 
		get 'black', :id => user1.id.to_s, :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval["_id"], user1.id.to_s
		assert_equal User.where(role: 4).count, 1

		get 'blacks', :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 1

		# change user1 to normal
		get 'black', :id => user1.id.to_s, :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval["_id"], user1.id.to_s
		assert_equal User.where(role: 4).count, 0

		sign_out

		clear(User)
	end

	test "05 should be opreate user to white" do 

		clear(User)

		#create admin user
		admin = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		admin.status = 2 
		admin.role = 1
		admin.save

		#create some normal user
		user2 = User.new(email: "test2@example.com", password: Encryption.encrypt_password("123456"))
		assert_equal user2.save, true

		assert_equal User.all.count, 2
		assert_equal User.where(role: 1).count, 1
		assert_equal User.where(role: 0).count, 1

		sign_in(admin.email, "123456")

		# *****************************
		# change user2 to white
		get 'white', :id => user2.id.to_s, :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval["_id"], user2.id.to_s
		assert_equal User.where(role: 2).count, 1

		get 'whites', :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 1

		# change user2 to normal
		get 'white', :id => user2.id.to_s, :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval["_id"], user2.id.to_s
		assert_equal User.where(role: 2).count, 0

		sign_out
	end

	test "06 should be change password to system password" do 
		clear(User)

		#create admin user
		admin = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		admin.status = 2 
		admin.role = 1
		admin.save

		#create some normal user
		user3 = User.create(email: "test3@example.com", password: Encryption.encrypt_password("123456"))

		assert_equal User.all.count, 2
		assert_equal User.where(role: 1).count, 1
		assert_equal User.where(role: 0).count, 1

		sign_in(admin.email, "123456")

		# ************
		# change user3 password to system
		assert_equal user3.password, Encryption.encrypt_password("123456")
		get 'system_pwd', :id => user3.id.to_s, :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval["_id"], user3.id.to_s
		assert_not_equal retval["password"], Encryption.encrypt_password("123456")
		assert_equal retval["tmp_password"].length, 8
		assert_not_equal User.find(user3.id.to_s).password, Encryption.encrypt_password("123456")
		
		sign_out

		clear(User)
	end

end