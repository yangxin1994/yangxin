FactoryGirl.define do
	factory :dsxl, class: Award do
		name '3DSXL'
  	type 1
  	description 'Nintendo Portable Game Suit'
    weighting 10000
  	#start_time Time.now
  	end_time Time.now.next_month
  	status 1
    surplus 10
    quantity 100 	
	end
end