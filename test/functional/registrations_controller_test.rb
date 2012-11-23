require 'test_helper'

class RegistrationsControllerTest < ActionController::TestCase
	test "should create user" do
		clear(User)

		user_hash = init_user
		user_hash["email"] = "illegal_email"
		post :create, :format => :json, :user => user_hash
		result = JSON.parse(@response.body)
		puts "aaaa"
		puts result.inspect
		assert_equal ErrorEnum::ILLEGAL_EMAIL.to_s, result["value"]["error_code"]

		user_hash = init_user
		user_hash["password_confirmation"] = "wrong_password_confirmation"
		post :create, :format => :json, :user => user_hash
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::WRONG_PASSWORD_CONFIRMATION.to_s, result["value"]["error_code"]
		
		user_hash = init_user
		post :create, :format => :json, :user => user_hash
		result = JSON.parse(@response.body)
		assert result["value"]

		user_hash = init_user
		user_hash["username"] = "another_username"
		post :create, :format => :json, :user => user_hash
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::EMAIL_EXIST.to_s, result["value"]["error_code"]
	end

	test "should send activate email" do
		clear(User)
		new_user = init_new_user
		activated_user = init_activated_user

		post :send_activate_email, :format => :json, :user => {"email" => "non-exist-email@test.com"}
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::USER_NOT_EXIST.to_s, result["value"]["error_code"]

		post :send_activate_email, :format => :json, :user => {"email" => activated_user.email}
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::USER_ACTIVATED.to_s, result["value"]["error_code"]

		post :send_activate_email, :format => :json, :user => {"email" => new_user.email}
		result = JSON.parse(@response.body)
		assert_equal true, result["value"]
	end

	test "should activate" do
		clear(User)
		jesse = init_jesse
		activate_info_1 = {"email" => jesse.email, "time" => Time.now.to_i - 1.months.to_i}
		activate_key_1 = Encryption.encrypt_activate_key(activate_info_1.to_json)
		activate_info_2 = {"email" => jesse.email, "time" => Time.now.to_i}
		activate_key_2 = Encryption.encrypt_activate_key(activate_info_2.to_json)

		post :activate, :format => :json, :activate_key => "wrong activate key"
		result = JSON.parse(@response.body)
		assert !result["success"]
		assert_equal ErrorEnum::ILLEGAL_ACTIVATE_KEY, result["value"]["error_code"]

		post :activate, :format => :json, :activate_key => activate_key_1
		result = JSON.parse(@response.body)
		assert !result["success"]
		assert_equal ErrorEnum::ACTIVATE_EXPIRED, result["value"]["error_code"]

		post :activate, :format => :json, :activate_key => activate_key_2
		result = JSON.parse(@response.body)
		assert result["success"]
		assert_equal User.find_by_email(jesse.email).auth_key, result["value"]["auth_key"]
	end

	def init_user
		user = {"email" => "jesse@test.com",
						"password" => "111111",
						"password_confirmation" => "111111",
						"username" => "jesse"}
		return user
	end
end
