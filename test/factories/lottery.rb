FactoryGirl.define  do
	factory :lottery do
		title 'New Lottery'
		description 'New Lottery'
		weight 100000
		
		#lottery_codes factory: :lottery_code
		#lottery_prizes factory: :lottery_dsxl
		end
end