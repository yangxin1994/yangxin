require 'test_helper'

class SystemUserTest < ActiveSupport::TestCase
	
=begin
	test "01 find_by_id method" do 
		clear(User)

		#
		#validate presence of true_name, password
		#
		system_user = SystemUser.new(password: Encryption.encrypt_password("123456")).save()
		assert_equal SystemUser.all.count, 0
		assert_equal system_user, false

		system_user = SystemUser.create(email: "1@example.com",system_user_type: 1, password: Encryption.encrypt_password("123456"), true_name: "lisi")
		assert_equal SystemUser.all.count, 1
		assert_equal system_user, SystemUser.all.first

		assert_equal SystemUser.find_by_id("4fff96616c6eea1204022005"), ErrorEnum::SYSTEM_USER_NOT_EXIST
		assert_equal SystemUser.find_by_id(system_user.id.to_s), system_user

		clear(User)
	end

	test "02 create_system_user" do 
		clear(User)

		#
		#validate presence of true_name, password
		#
		# username and email , has one of them at least
		#

		#lack true_name
		new_system_user = {email: "test@example.com", username:"test", password: "123456"}
		system_user = SystemUser.create_system_user(new_system_user)
		assert_equal SystemUser.all.count, 0

		# lack username and email
		new_system_user = {password: "123456", true_name: "lisi"}
		system_user = SystemUser.create_system_user(new_system_user)
		assert_equal SystemUser.all.count, 0
		assert_equal system_user, ErrorEnum::SYSTEM_USER_MUST_EMAIL_OR_USERNAME

		#
		new_system_user = {email: "test@example.com", username:"test", password: "123456", true_name: "lisi"}
		system_user = SystemUser.create_system_user(new_system_user)
		assert system_user.instance_of?(AnswerAuditor)
		assert_equal system_user.status, 4
		assert_equal system_user.password, Encryption.encrypt_password("123456")

		new_system_user = {email: "test2@example.com", password: "123456", true_name: "lisi", system_user_type: 2}
		system_user = SystemUser.create_system_user(new_system_user)
		assert system_user.instance_of?(SurveyAuditor)
		assert_equal system_user.password, Encryption.encrypt_password("123456")

		new_system_user = {email: "test3@example.com", password: "123456", system_user_type: 4, true_name: "lisi"}
		system_user = SystemUser.create_system_user(new_system_user)
		assert system_user.instance_of?(EntryClerk)
		assert_equal system_user.password, Encryption.encrypt_password("123456")

		new_system_user = {email: "test4@example.com", password: "123456", system_user_type: 8, true_name: "lisi"}
		system_user = SystemUser.create_system_user(new_system_user)
		assert system_user.instance_of?(Interviewer)
		assert_equal system_user.password, Encryption.encrypt_password("123456")

		new_system_user = {email: "test5@example.com", password: "123456", system_user_type: "typw1", true_name: "lisi"}
		system_user = SystemUser.create_system_user(new_system_user)
		assert_equal system_user, ErrorEnum::SYSTEM_USER_TYPE_ERROR

		new_system_user = {email: "test5@example.com", password: "123456", system_user_type: 3, true_name: "lisi"}
		system_user = SystemUser.create_system_user(new_system_user)
		assert_equal system_user, ErrorEnum::SYSTEM_USER_RANGE_ERROR

		new_system_user = {email: "test@example.com", password: "123456", true_name: "lisi"}
		system_user = SystemUser.create_system_user(new_system_user)
		assert_equal system_user, ErrorEnum::EMAIL_EXIST

		new_system_user = {username: "test", password: "123456", true_name: "lisi"}
		system_user = SystemUser.create_system_user(new_system_user)
		assert_equal system_user, ErrorEnum::USERNAME_EXIST

		clear(User)
	end


	test "03 update_system_user" do 
		clear(User)

		new_system_user = {email: "test@example.com", password: "123456", true_name: "lisi"}
		system_user = SystemUser.create_system_user(new_system_user)
		assert system_user.instance_of?(AnswerAuditor)
		assert_equal system_user.status, 4
		assert_equal system_user.password, Encryption.encrypt_password("123456")
		system_user = SystemUser.update_system_user(system_user.id.to_s, 
			{:email => "test2@example.com",:true_name => "test", :lock => true })
		assert_equal system_user.email, "test2@example.com"
		assert_equal system_user.lock, true
		assert_equal system_user.true_name, "test"
		assert_equal system_user.status, 4

		clear(User)
	end

	test "04 list_by_type" do
		clear(User) 

		aa_user = AnswerAuditor.create_system_user(email: "test2@example.com", 
				password: Encryption.encrypt_password("123456"), true_name: "lisi")
		sa_user = SurveyAuditor.create_system_user(system_user_type: 2, email: "test3@example.com", 
				password: Encryption.encrypt_password("123456"), true_name: "lisi")
		ec_user = EntryClerk.create_system_user(system_user_type: 4,email: "test4@example.com", 
				password: Encryption.encrypt_password("123456"), true_name: "lisi")
		iv_user = Interviewer.create_system_user(system_user_type: 8,email: "test5@example.com",
				password: Encryption.encrypt_password("123456"), 
				true_name: "lisi")

		assert_equal aa_user.system_user_type, 1
		assert_equal sa_user.system_user_type, 2
		assert_equal ec_user.system_user_type, 4
		assert_equal iv_user.system_user_type, 8

		assert_equal SystemUser.all.count, 4
		assert_equal SystemUser.list_by_type(0).count, 0
		assert_equal SystemUser.list_by_type(1).count, 1
		assert_equal SystemUser.list_by_type(2).count, 1
		assert_equal SystemUser.list_by_type(4).count, 1
		assert_equal SystemUser.list_by_type(8).count, 1
		assert_equal SystemUser.list_by_type(15).count, 4
		assert_equal SystemUser.list_by_type(16), ErrorEnum::SYSTEM_USER_RANGE_ERROR
		assert_equal SystemUser.list_by_type("type"), ErrorEnum::SYSTEM_USER_TYPE_ERROR

		clear(User)
	end

	test "05 list_by_type_and_lock" do
		clear(User) 

		aa_user = AnswerAuditor.create_system_user(email: "test2@example.com", 
				password: Encryption.encrypt_password("123456"), true_name: "lisi")
		sa_user = SurveyAuditor.create_system_user(system_user_type: 2, email: "test3@example.com", 
				password: Encryption.encrypt_password("123456"), true_name: "lisi")
		ec_user = EntryClerk.create_system_user(system_user_type: 4,email: "test4@example.com", 
				password: Encryption.encrypt_password("123456"), true_name: "lisi")
		iv_user = Interviewer.create_system_user(system_user_type: 8,email: "test5@example.com",
				password: Encryption.encrypt_password("123456"), 
				true_name: "lisi", lock: true)

		assert_equal aa_user.system_user_type, 1
		assert_equal sa_user.system_user_type, 2
		assert_equal ec_user.system_user_type, 4
		assert_equal iv_user.system_user_type, 8

		assert_equal SystemUser.all.count, 4
		assert_equal SystemUser.list_by_type_and_lock(15, false).count, 3
		assert_equal SystemUser.list_by_type_and_lock(15, true).count, 1
		assert_equal SystemUser.list_by_type_and_lock(16, true), ErrorEnum::SYSTEM_USER_RANGE_ERROR
		assert_equal SystemUser.list_by_type_and_lock("type",true), ErrorEnum::SYSTEM_USER_TYPE_ERROR

		clear(User)
	end
=end
end
