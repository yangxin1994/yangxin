FactoryGirl.define do

	factory :quill_user, class: User do
		password Encryption.encrypt_password("123123123")
		status 4
		point 1000
		factory :admin_foo do
			email "admin_foo@gmail.com"
			username "admin_foo"
			role 16
		end
		factory :user_bar do
			email "user_bar@gmail.com"
			username "user_bar"
			role 0
		end
		
	end

	factory :new_user, class: User do
		email "new_user@test.com"
		password Encryption.encrypt_password("111111")
		username "new_user"
	end

	factory :activated_user, class: User do
		email "activated_user@test.com"
		password Encryption.encrypt_password("111111")
		username "activated_user"
		status 2
		activate_time Time.now.to_i
	end

	factory :jesse, class: User do
		email "jesse@test.com"
		password Encryption.encrypt_password("123456")
		username "jesse"
		status 4
		activate_time Time.now.to_i
	end

	factory :oliver, class: User do
		email "oliver@test.com"
		password Encryption.encrypt_password("123456")
		username "oliver"
		status 4
		activate_time Time.now.to_i
	end

	factory :lisa, class: User do
		email "lisa@test.com"
		password Encryption.encrypt_password("123456")
		username "lisa"
		status 4
		activate_time Time.now.to_i
	end

	factory :polly, class: User do
		email "polly@test.com"
		password Encryption.encrypt_password("111111")
		username "polly"
		status 4
		activate_time Time.now.to_i
	end

	factory :admin, class: User do
		email "admin@test.com"
		password Encryption.encrypt_password("111811")
		username "admin"
		status 4
		role 16
		activate_time Time.now.to_i
	end

	factory :survey_auditor, class: User do
		email "survey_auditor@test.com"
		password Encryption.encrypt_password("123456")
		username "survey_auditor"
		status 4
		role 8
		activate_time Time.now.to_i
	end

	factory :answer_auditor, class: User do
		email "answer_auditor@test.com"
		password Encryption.encrypt_password("123456")
		username "answer_auditor"
		status 4
		role 4
		activate_time Time.now.to_i
	end

	factory :interviewer, class: User do
		email "interviewer@test.com"
		password Encryption.encrypt_password("123456")
		username "interviewer"
		status 4
		role 2
		activate_time Time.now.to_i
	end

	factory :entry_clerk, class: User do
		email "entry_clerk@test.com"
		password Encryption.encrypt_password("123456")
		username "entry_clerk"
		status 4
		role 1
		activate_time Time.now.to_i
	end
end
