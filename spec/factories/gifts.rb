FactoryGirl.define do
	factory :gift do |f|
		f.sequence(:status) { |n| 2**(n%2) }
		f.sequence(:type) { |n| 2**(n%3) }
		f.sequence(:title) { |n| "the #{n}th gift" }
		f.sequence(:description) { |n| "description of the #{n}th gift" }
		f.quantity 100
		f.point 100
	end
end