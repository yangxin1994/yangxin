FactoryGirl.define  do
	factory :lottery_code do
		code "dafasdfasfs"
		lottery factory: :lottery
		#user factory: :user_bar
	end
end