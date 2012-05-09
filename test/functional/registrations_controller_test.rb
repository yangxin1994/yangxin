require 'test_helper'

class RegistrationsControllerTest < ActionController::TestCase
	test "should create user" do
		clear(User, UserInformation)

		user_hash, user_information = *init_user_and_user_information
		user_hash["email"] = "illegal_email"
		post :create, :format => :json, :user => user_hash, :user_information => user_information
		assert_equal ErrorEnum::ILLEGAL_EMAIL.to_s, @response.body
		
		user_hash, user_information = *init_user_and_user_information
		user_hash["password_confirmation"] = "wrong_password_confirmation"
		post :create, :format => :json, :user => user_hash, :user_information => user_information
		assert_equal ErrorEnum::WRONG_PASSWORD_CONFIRMATION.to_s, @response.body
		
		user_hash, user_information = *init_user_and_user_information
		post :create, :format => :json, :user => user_hash, :user_information => user_information
		assert_equal true.to_s, @response.body
	end

	test "should check email" do
		post :email_illegal, :format => :json, :email => "correct_email@test.com"
		assert_equal true.to_s, @response.body

		get :email_illegal, :format => :json, :email => "correct_email@test.com"
		assert_equal true.to_s, @response.body

		post :email_illegal, :format => :json, :email => "wrong_email"
		assert_equal false.to_s, @response.body

		get :email_illegal, :format => :json, :email => "wrong_email"
		assert_equal false.to_s, @response.body
	end

	test "should send activate email" do
		clear(User)
		new_user = init_new_user
		activated_user = init_activated_user

		post :send_activate_email, :format => :json, :email => "non-exist-email@test.com"
		assert_equal ErrorEnum::EMAIL_NOT_EXIST.to_s, @response.body

		post :send_activate_email, :format => :json, :email => activated_user.email
		assert_equal ErrorEnum::EMAIL_ACTIVATED.to_s, @response.body

		post :send_activate_email, :format => :json, :email => new_user.email
		assert_equal true.to_s, @response.body
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


	def init_user_and_user_information
		user = {"email" => "jesse@test.com",
						"password" => "111111",
						"password_confirmation" => "111111",
						"username" => "jesse"}
		user_information = {"email" => "jesse@test.com",
												"realname" => "Jesse Yang"}
		return [user, user_information]
	end
end
