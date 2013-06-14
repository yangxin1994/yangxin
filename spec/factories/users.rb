FactoryGirl.define do
	factory :admin, class: User do
		username "admin"
		email "admin@test.com"
		password Encryption.encrypt_password('123456')
		role 63
		status 4
	end
end