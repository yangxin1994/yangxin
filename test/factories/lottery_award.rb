FactoryGirl.define  do
	factory :lottery_dsxl do
		weighting 100
		start_time DataTime.now
		end_time DataTime.now.next_month
		point 1000
		weight 10000
		
	end
end