FactoryGirl.define do
	factory :admin, class: User do
		username "admin"
		email "admin@test.com"
		password Encryption.encrypt_password('123456')
		role 63
		status 4
		user_role 4
	end

	factory :sample, class: User do |f|
		f.sequence(:email) { |n| "foo#{n}@example.com" }
		f.sequence(:username) { |n| "foo#{n}" }
		f.is_block false
	end
end