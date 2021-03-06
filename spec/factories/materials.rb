FactoryGirl.define do
	factory :material do |f|
		f.sequence(:material_type) { |n| 2**(n%2) }
		f.sequence(:title) { |n| "the #{n}th gift" }
		f.value "/image/1.jpg"
	end
end