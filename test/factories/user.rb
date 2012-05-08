FactoryGirl.define do
	factory :new_user, class: User do
		email "new_user@test.com"
		password Encryption.encrypt_password("111111")
		username "new_user"
	end

	factory :activated_user, class: User do
		email "activated_user@test.com"
		password Encryption.encrypt_password("111111")
		username "activated_user"
		status 1
		activate_time Time.now.to_i
	end

	factory :jesse, class: User do
		email "jesse@test.com"
		password Encryption.encrypt_password("123456")
		username "jesse"
		status 1
		activate_time Time.now.to_i
	end

	factory :oliver, class: User do
		email "oliver@test.com"
		password Encryption.encrypt_password("123456")
		username "oliver"
		status 1
		activate_time Time.now.to_i
	end
end
