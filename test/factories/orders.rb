# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
	factory :order do
		type 0
		status 0
		recipient "Matz"
		phone_number "00332457"
		gift factory: :gift
		user factory: :user_bar
	end
end
