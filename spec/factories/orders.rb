FactoryGirl.define do
	factory :order do
		code { Time.now.strftime("%Y%m%d") + sprintf("%05d",rand(10000)) }
		type { [1, 2, 4, 8, 16, 32, 64][rand(7)] }
		status { [1, 2, 4, 8, 16][rand(5)] }
		source { [1, 2, 4][rand(3)] }
		amount { 333 if [1, 2, 4, 8, 16].include?(type)}
		alipay_account {"tb_12323123123" if type == 4 or type == 8}
		mobile {"13548548654" if [1, 2, 32].include?(type)}
		qq {"10010" if type == 16 }
		user_name {"lucker" if type == 32 }
		address {"beijing" if type == 32}
		postcode {"108012" if type == 32}
	end

	factory :wait_order, class: Order do |f|
		f.code { Time.now.strftime("%Y%m%d") + sprintf("%05d",rand(10000)) }
		f.sequence(:type) { |n| 2**(n%7) }
		f.status Order::WAIT
		f.sequence(:source) { |n| 2**(n%3) }
		f.amount 10
	end

	factory :handle_order, class: Order do |f|
		f.code { Time.now.strftime("%Y%m%d") + sprintf("%05d",rand(10000)) }
		f.sequence(:type) { |n| 2**(n%7) }
		f.status Order::HANDLE
		f.sequence(:source) { |n| 2**(n%3) }
		f.amount 10
	end

	factory :success_order, class: Order do |f|
		f.code { Time.now.strftime("%Y%m%d") + sprintf("%05d",rand(10000)) }
		f.sequence(:type) { |n| 2**(n%7) }
		f.status Order::SUCCESS
		f.sequence(:source) { |n| 2**(n%3) }
		f.amount 10
	end

	factory :fail_order, class: Order do |f|
		f.code { Time.now.strftime("%Y%m%d") + sprintf("%05d",rand(10000)) }
		f.sequence(:type) { |n| 2**(n%7) }
		f.status Order::FAIL
		f.sequence(:source) { |n| 2**(n%3) }
		f.amount 10
	end
end