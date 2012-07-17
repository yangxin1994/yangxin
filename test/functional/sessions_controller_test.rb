require 'test_helper'

class SessionsControllerTest < ActionController::TestCase
	
	test "should login" do
		clear(User)
		jesse = FactoryGirl.build(:jesse)
		jesse.save
		new_user = FactoryGirl.build(:new_user)
		new_user.save

		post :create, :format => :json, :user => {"email_username" => "wrong_email@test.com", "password" => Encryption.decrypt_password(jesse.password)}
		assert_equal ErrorEnum::USER_NOT_EXIST.to_s, @response.body

		post :create, :format => :json, :user => {"email_username" => new_user.email, "password" => Encryption.decrypt_password(new_user.password)}
		assert_equal ErrorEnum::USER_NOT_ACTIVATED.to_s, @response.body

		post :create, :format => :json, :user => {"email_username" => jesse.email, "password" => "wrong password"}
		assert_equal ErrorEnum::WRONG_PASSWORD.to_s, @response.body

		post :create, :format => :json, :user => {"email_username" => jesse.email, "password" => Encryption.decrypt_password(jesse.password)}
		assert_equal true.to_s, @response.body
	end

	test "should send password email" do
		clear(User)
		jesse = FactoryGirl.build(:jesse)
		jesse.save
		
		post :send_password_email, :format => :json, :email => "wrong_email@test.com"
		assert_equal ErrorEnum::USER_NOT_EXIST.to_s, @response.body

		post :send_password_email, :format => :json, :email => jesse.email
		assert_equal true.to_s, @response.body
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
		assert_redirected_to forget_password_url, "activate an user with expired activate key"

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
		assert_equal false.to_s, @response.body

		get :new_password, :format => :json, :user => {"email" => jesse.email, "password" => "new_password", "password_confirmation" => "new_password"}, :password_key => password_key_1
		assert_equal ErrorEnum::RESET_PASSWORD_EXPIRED.to_s, @response.body

		get :new_password, :format => :json, :user => {"email" => "wrong_email@test.com", "password" => "new_password", "password_confirmation" => "new_password"}, :password_key => password_key_2
		assert_equal ErrorEnum::USER_NOT_EXIST.to_s, @response.body

		get :new_password, :format => :json, :user => {"email" => jesse.email, "password" => "new_password", "password_confirmation" => "wrong_confirmation"}, :password_key => password_key_2
		assert_equal ErrorEnum::WRONG_PASSWORD_CONFIRMATION.to_s, @response.body
		
		get :new_password, :format => :json, :user => {"email" => jesse.email, "password" => "new_password", "password_confirmation" => "new_password"}, :password_key => password_key_2
		assert_equal true.to_s, @response.body
	end
end
