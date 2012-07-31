FactoryGirl.define do
	factory :dsxl, class: Award do
		name '3DSXL'
  	type 1
  	quantity 20
  	description 'Nintendo Portable Game Suit'
  	start_time Time.now
  	end_time Time.now.next_month
  	status 1
  	
	end
end