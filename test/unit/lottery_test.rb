require 'test_helper'

class UserTest < ActiveSupport::TestCase
	# setup do
	# 	clear(User, Lottery)
	# 	FoctoryGirl.create(:admin_bar)
	# end
end

class LotteryTest < ActiveSupport::TestCase
	setup do
		clear(Award, Lottery,LotteryCode,User)
		@lottery = FactoryGirl.create(:lottery)
    @lottery_code = FactoryGirl.create(:lottery_code) 
    @user_foo = FactoryGirl.created(:user_foo)
	end

  test "should add an award" do
  	assert @lottery.awards.empty?
  	@lottery.add_an_award(:name => "PSV",
  											 :type => 1,
  											 :quantity => 23,
  											 :description => "sony playstation portable vita"
  		)
  	assert_not_nil !@lottery.awards[0].created_at
  end

  test "should add a lottery code" do
  	assert @lottery.lottery_codes.empty?
  	@lottery.add_a_lottery_code
    assert_not_nil !@lottery.lottery_codes[0].created_at
  end
  
  test "should give one lottery code to a user" do
    @lottery.give_a_lottery_code_to(@user_foo)
    assert true
  end

  test "should draw a lottery" do
    
  end

  test "should make a interval" do
     
  end

end

