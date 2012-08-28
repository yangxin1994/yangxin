require 'test_helper'

class SessionsControllerTest < ActionController::TestCase
	
	test "should login" do
		clear(User)
		jesse = FactoryGirl.build(:jesse)
		jesse.save
		new_user = FactoryGirl.build(:new_user)
		new_user.save

		post :create, :format => :json, :user => {"email_username" => "wrong_email@test.com", "password" => Encryption.decrypt_password(jesse.password)}
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::USER_NOT_EXIST.to_s, result["value"]["error_code"]

		post :create, :format => :json, :user => {"email_username" => new_user.email, "password" => Encryption.decrypt_password(new_user.password)}
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::USER_NOT_ACTIVATED.to_s, result["value"]["error_code"]

		post :create, :format => :json, :user => {"email_username" => jesse.email, "password" => "wrong password"}
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::WRONG_PASSWORD.to_s, result["value"]["error_code"]

		post :create, :format => :json, :user => {"email_username" => jesse.email, "password" => Encryption.decrypt_password(jesse.password)}
		result = JSON.parse(@response.body)
		assert_equal 2, result["value"]["status"]
	end

	test "should send password email" do
		clear(User)
		jesse = FactoryGirl.build(:jesse)
		jesse.save
		
		post :send_password_email, :format => :json, :email => "wrong_email@test.com"
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::USER_NOT_EXIST.to_s, result["value"]["error_code"]

		post :send_password_email, :format => :json, :email => jesse.email
		result = JSON.parse(@response.body)
		assert_equal true, result["value"]
	end

	test "should input new password" do
		clear(User)
		jesse = FactoryGirl.build(:jesse)
		jesse.save
		password_info_1 = {"email" => jesse.email, "time" => Time.now.to_i - 1.months.to_i}
		password_key_1 = Encryption.encrypt_activate_key(password_info_1.to_json)
		password_info_2 = {"email" => jesse.email, "time" => Time.now.to_i}
		password_key_2 = Encryption.encrypt_activate_key(password_info_2.to_json)

		get :input_new_password, :password_key => "wrong password key"
		assert_redirected_to "/500"

		get :input_new_password, :password_key => password_key_1
		assert_redirected_to :action => "forget_password"

		get :input_new_password, :password_key => password_key_2
		assert_response :success
	end

	test "should create new password" do
		clear(User)
		jesse = FactoryGirl.build(:jesse)
		jesse.save
		password_info_1 = {"email" => jesse.email, "time" => Time.now.to_i - 1.months.to_i}
		password_key_1 = Encryption.encrypt_activate_key(password_info_1.to_json)
		password_info_2 = {"email" => jesse.email, "time" => Time.now.to_i}
		password_key_2 = Encryption.encrypt_activate_key(password_info_2.to_json)

		get :new_password, :format => :json, :user => {"email" => jesse.email, "password" => "new_password", "password_confirmation" => "new_password"}, :password_key => "wrong password key"
		result = JSON.parse(@response.body)
		assert_equal false, result["success"]

		get :new_password, :format => :json, :user => {"email" => jesse.email, "password" => "new_password", "password_confirmation" => "new_password"}, :password_key => password_key_1
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::RESET_PASSWORD_EXPIRED.to_s, result["value"]["error_code"]

		get :new_password, :format => :json, :user => {"email" => "wrong_email@test.com", "password" => "new_password", "password_confirmation" => "new_password"}, :password_key => password_key_2
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::USER_NOT_EXIST.to_s, result["value"]["error_code"]

		get :new_password, :format => :json, :user => {"email" => jesse.email, "password" => "new_password", "password_confirmation" => "wrong_confirmation"}, :password_key => password_key_2
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::WRONG_PASSWORD_CONFIRMATION.to_s, result["value"]["error_code"]
		
		get :new_password, :format => :json, :user => {"email" => jesse.email, "password" => "new_password", "password_confirmation" => "new_password"}, :password_key => password_key_2
		result = JSON.parse(@response.body)
		assert_equal true, result["value"]
	end
end
