FactoryGirl.define do
	factory :dsxl, class: Prize do
		name '3DSXL'
  	type 1
  	description 'Nintendo Portable Game Suit'
    weight 100
  	#start_time Time.now
  	# end_time Time.now.next_month
  	status 1
    surplus 1
    quantity 100 	
	end
  factory :dsxl_d, class: Prize do
    name '3DSXL'
    type 1
    description 'Nintendo Portable Game Suit'
    weight 100000
    #start_time Time.now
    # end_time Time.now.next_month
    status 1
    surplus 1
    quantity 100  
  end
end