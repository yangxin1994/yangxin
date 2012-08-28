require 'test_helper'

class RegistrationsControllerTest < ActionController::TestCase
	test "should create user" do
		clear(User)

		user_hash = init_user
		user_hash["email"] = "illegal_email"
		post :create, :format => :json, :user => user_hash
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::ILLEGAL_EMAIL.to_s, result["value"]["error_code"]

		user_hash = init_user
		user_hash["password_confirmation"] = "wrong_password_confirmation"
		post :create, :format => :json, :user => user_hash
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::WRONG_PASSWORD_CONFIRMATION.to_s, result["value"]["error_code"]
		
		user_hash = init_user
		post :create, :format => :json, :user => user_hash
		result = JSON.parse(@response.body)
		assert_equal true, result["value"]

		user_hash = init_user
		user_hash["email"] = "another_email@test.com"
		post :create, :format => :json, :user => user_hash
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::USERNAME_EXIST.to_s, result["value"]["error_code"]

		user_hash = init_user
		user_hash["username"] = "another_username"
		post :create, :format => :json, :user => user_hash
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::EMAIL_EXIST.to_s, result["value"]["error_code"]
	end

	test "should check email" do
		post :email_illegal, :format => :json, :email => "correct_email@test.com"
		result = JSON.parse(@response.body)
		assert_equal true, result["value"]

		get :email_illegal, :format => :json, :email => "correct_email@test.com"
		result = JSON.parse(@response.body)
		assert_equal true, result["value"]

		post :email_illegal, :format => :json, :email => "wrong_email"
		result = JSON.parse(@response.body)
		assert_equal false, result["value"]

		get :email_illegal, :format => :json, :email => "wrong_email"
		result = JSON.parse(@response.body)
		assert_equal false, result["value"]
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
		new_user = init_new_user
		activate_info_1 = {"email" => new_user.email, "time" => Time.now.to_i - 1.months.to_i}
		activate_key_1 = Encryption.encrypt_activate_key(activate_info_1.to_json)
		activate_info_2 = {"email" => new_user.email, "time" => Time.now.to_i}
		activate_key_2 = Encryption.encrypt_activate_key(activate_info_2.to_json)

		get :activate, :activate_key => "wrong activate key"
		assert_redirected_to "/500"

		get :activate, :activate_key => activate_key_1
		assert_redirected_to input_activate_email_path, "activate an user with expired activate key"

		get :activate, :activate_key => activate_key_2
		assert_redirected_to sessions_path, "fail to activate an user"
	end

	def init_user
		user = {"email" => "jesse@test.com",
						"password" => "111111",
						"password_confirmation" => "111111",
						"username" => "jesse"}
		return user
	end
end
