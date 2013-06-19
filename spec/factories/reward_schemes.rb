FactoryGirl.define do
	factory :reward_scheme do
		type { [1, 2, 4, 8][ rand(4) ] }  ##Enum with [1, 2, 4, 8]
		amount {rand(100) + 1}
		prizes {[{ :id => '87asdfsd9f7sdf', :prob => 0.01, :deadline => (Time.now.to_i + 86400), :amount => 10 }] if type == 8 }

		initialize_with { new({:need_review => false, :rewards => [ attributes ] }) }
	end

	factory :mobile_reward_scheme, parent: :reward_scheme do  ## Use for batch create reward schemes
		type 1
		amount 10
		prizes []
	end

	factory :alipay_reward_scheme, parent: :reward_scheme do  ## Use for batch create reward schemes
		type 2
		amount 5
		prizes []
	end

	factory :you_reward_scheme, parent: :reward_scheme do  ## Use for batch create reward schemes
		type 4
		amount 50
		prizes []
	end

	factory :lottery_reward_scheme, parent: :reward_scheme do  ## Use for batch create reward schemes
		type 8
		amount 0
		prizes {[{ :id => '87asdfsd9f7sdf', :prob => 0.01, :deadline => (Time.now.to_i + 86400), :amount => 10 }]}
	end

end