FactoryGirl.define do
	factory :agent_task do |f|
		f.sequence(:status) { |n| 2**(n%2) }
		f.sequence(:email) { |n| "#{n}@test.com" }
		f.password Encryption.encrypt_password("111111")
		f.sequence(:description) { |n| "description of the #{n}th agent task" }
		f.count 100
	end
end