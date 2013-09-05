FactoryGirl.define do
	factory :name, class: SampleAttribute do
		name "name"
		type 0
	end

	factory :gender, class: SampleAttribute do
		name "gender"
		type 1
		enum_array ["male", "female"]
	end

	factory :weight, class: SampleAttribute do
		name "weight"
		type 2
	end

	factory :birth, class: SampleAttribute do
		name "birth"
		type 3
		date_type 2
	end

	factory :salary, class: SampleAttribute do
		name "salary"
		type 4
	end

	factory :graduated_at, class: SampleAttribute do
		name "graduated_at"
		type 5
		date_type 0
	end

	factory :address, class: SampleAttribute do
		name "address"
		type 6
	end

	factory :interests, class: SampleAttribute do
		name "interests"
		type 7
		element_type 1
		enum_array ["basketball", "football", "swimming", "pingpang"]
	end
end