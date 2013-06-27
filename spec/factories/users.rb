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
		f.sequence(:username) { |n| "foo#{n}@example.com" }
		f.sequence(:email) { |n| "foo#{n}@example.com" }
		f.sequence(:is_block) { |n| (n%2)==1 }
		f.user_role 1
	end

	factory :sample_with_attributes, class: User do
		email "foo@test.com"
		gender 0
	end

	factory :survey_creator, class: User do |c|
		c.sequence(:email) { |n| "creator_#{n}@example.com"}
		c.mobile {"183#{[*(1..8)].shuffle.join}"}   ##random string
	end
end