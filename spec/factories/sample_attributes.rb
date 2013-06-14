FactoryGirl.define do
	factory :gender, class: SampleAttribute do
		name "gender"
		type 1
		enum_array ["mail", "female"]
	end

	factory :birth, class: SampleAttribute do
		name "birth"
		type 3
		date_type 2
	end

	factory :interests, class: SampleAttribute do
		name "interests"
		type 7
		element_type 1
		enum_array ["basketball", "football", "swimming", "pingpang"]
	end
end