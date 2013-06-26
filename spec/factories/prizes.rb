FactoryGirl.define do
	factory :prize do |f|
		f.status 1
		f.sequence(:type) { |n| 2**(n%2) }
		f.sequence(:title) { |n| "the #{n}th prize" }
		f.sequence(:description) { |n| "description of the #{n}th prize" }
	end
end