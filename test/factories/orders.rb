# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
	factory :order do
		type 0
		status 0
		gift factory: :gift
		user factory: :user_bar
	end
end
