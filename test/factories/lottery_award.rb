FactoryGirl.define  do
	factory :lottery_dsxl, class: LotteryAward do
		weighting 10000
		start_time DateTime.now
		end_time DateTime.now.next_month
		surplus 10
		quantity 100
		award factory: :dsxl
	end
end