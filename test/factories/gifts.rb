# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
	factory :gift do
		name 'Kindle 4'
		type 1
		point 500
		quantity 20
		surplus 10
		description 'amazon Kindle'
		status 1
	end
	factory :rmb100, class: Gift do
		name '100 yuan'
		type 0
		point 500
		surplus 10
		description '100 yuan'
		status 1
	end
	factory :kindle, class: Gift do
		name 'Kindle 4'
		type 1
		point 500
		quantity 20
		surplus 10
		description 'amazon Kindle'
		status 1
	end
	factory :mobile100, class: Gift do
		name 'mobile100'
		type 2
		point 500
		quantity 20
		surplus 10
		description 'mobile100'
		status 1
	end
	factory :lottery_gift, class: Gift do
		name 'mobile100'
		type 3
		point 500
		quantity 20
		surplus 10
		lottery factory: :lottery
		description 'mobile100'
		status 1
	end
end
