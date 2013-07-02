FactoryGirl.define do
	factory :user do |f|
		f.sequence(:email) { |n| "foo#{n}@example.com" }
		f.username "test"
	end
end
