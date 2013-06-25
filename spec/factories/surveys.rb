FactoryGirl.define do
	factory :survey do |s|
		s.sequence(:status) { |n| 2 ** ((n + 3) % 3) }
		s.sequence(:title) { |n| "title#{n}news" }
	end

end