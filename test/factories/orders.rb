# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
	factory :order do
		order_type 0
		status 0
		recipient "Matz"
		phone_number "00332457"
		#present
		#user
	end
end
