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
