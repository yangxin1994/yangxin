require 'test_helper'

class UserTest < ActiveSupport::TestCase
	test "user login" do
		clear(User)

		new_user = init_new_user
		activated_user = init_activated_user

		retval = User.login("wrong_email@test.com", "111111", "127.0.0.1")
		assert_equal ErrorEnum::EMAIL_NOT_EXIST, retval, "non-exist user signs in"

		retval = User.login(new_user.email, Encryption.decrypt_password(new_user.password), "127.0.0.1")
		assert_equal ErrorEnum::EMAIL_NOT_ACTIVATED, retval, "user that has not been activated signs in"

		retval = User.login(activated_user.email, "wrong_password", "127.0.0.1")
		assert_equal ErrorEnum::WRONG_PASSWORD, retval, "user with wrong password signs in"

		retval = User.login(activated_user.email, Encryption.decrypt_password(new_user.password), "127.0.0.1")
		assert_equal true, retval, "fail to login"
	end

	test "user activation" do
		clear(User)

		user = FactoryGirl.build(:new_user)
		user.save

		activate_info = {"email" => user.email, "time" => Time.now.to_i - 1.months.to_i}
		retval = User.activate(activate_info)
		assert_equal ErrorEnum::ACTIVATE_EXPIRED, retval, "activate an expired user"
		user = User.find_by_email(user.email)
		assert_equal 0, user.status, "activate a expired user"

		activate_info = {"email" => user.email, "time" => Time.now.to_i}
		retval = User.activate(activate_info)
		assert retval, "fail to activate an user"
		user = User.find_by_email(user.email)
		assert_equal 1, user.status, "fail to activate an user"

		activate_info = {"email" => "t@test.com", "time" => Time.now.to_i}
		retval = User.activate(activate_info)
		assert_equal ErrorEnum::EMAIL_NOT_EXIST, retval, "activate a non-exist user"
	end

	test "new user creation" do
		clear(User)

		new_user = {"email" => "test@test.com", "password" => "oopsdata", "password_confirmation" => "oopsdata", "username" => "test"}
		user = User.check_and_create_new(new_user)
		assert_equal User, user.class, "fail to create a new user"
		user = User.find_by_email("test@test.com")
		assert user, "fail to obtain the user just created"
		assert_equal user.email, new_user["email"], "fail to obtain the user just created"

		new_user = {"email" => "test@test.com", "password" => "oopsdata", "password_confirmation" => "oopsdata", "username" => "test"}
		user = User.check_and_create_new(new_user)
		assert_equal ErrorEnum::EMAIL_NOT_ACTIVATED, user, "allow to create an user that already exists"
		remove_user("test@test.com")

		new_user = {"email" => "testtest.com", "password" => "oopsdata", "password_confirmation" => "oopsdata", "username" => "test"}
		user = User.check_and_create_new(new_user)
		assert_equal ErrorEnum::ILLEGAL_EMAIL, user, "allow to create an user that has an illegal email address"
		remove_user("testtest.com")

		new_user = {"email" => "test@test.com", "password" => "oopsdata", "password_confirmation" => "0opsdata", "username" => "test"}
		user = User.check_and_create_new(new_user)
		assert_equal ErrorEnum::WRONG_PASSWORD_CONFIRMATION, user, "fail to correctly check the confirmation of password"
	end
end
