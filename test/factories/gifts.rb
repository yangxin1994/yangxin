# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
	factory :gift do
		name 'Kindle 4'
		type 1
		point 500
		quantity 20
		surplus 10
		description 'amazon Kindle'
		start_time Time.now
		end_time Time.now.next_month
		status 1
		
	end
end
