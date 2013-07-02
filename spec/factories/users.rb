FactoryGirl.define do
	factory :admin, class: User do
		username "admin"
		email "admin@test.com"
		password Encryption.encrypt_password('123456')
		role 63
		status 4
		user_role 4
	end

	factory :admin_another, parent: :admin do |a|
		a.sequence(:username) { |n| "admin_#{n}"}
		a.sequence(:email) { |n| "admin_#{n}@test.com"}
		a.password Encryption.encrypt_password('123456')
		a.role 63
		a.status 4
		a.user_role 4
	end

	factory :sample, class: User do |f|
		f.sequence(:username) { |n| "foo#{n}@example.com" }
		f.sequence(:email) { |n| "foo#{n}@example.com" }
		password Encryption.encrypt_password('123456')
		f.mobile {"183#{[*(1..8)].shuffle.join}"}   ##random string
		f.sequence(:is_block) { |n| (n%2)==1 }
		f.user_role 1
	end

	factory :sample_with_attributes, class: User do
		email "foo@test.com"
		gender 0
	end

	factory :survey_creator, class: User do |c|
		password Encryption.encrypt_password('123456')
		c.sequence(:email) { |n| "creator_#{n}@example.com"}
		c.mobile {"183#{[*(1..8)].shuffle.join}"}   ##random string
	end

	factory :answer_auditor, class: User do |aa|
		aa.username "admin"
		aa.password Encryption.encrypt_password('123456')
		aa.sequence(:email) { |n| "creator_#{n}@example.com"}
		aa.mobile {"183#{[*(1..8)].shuffle.join}"}   ##random string
		aa.role 63
		aa.status 4
		aa.user_role 9
	end
end
