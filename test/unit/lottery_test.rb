require 'test_helper'

class LotteryTest < ActiveSupport::TestCase
	setup do
		clear(Prize, Lottery, LotteryCode, User)
		#@lottery = FactoryGirl.create(:lottery)
    @lottery_code = FactoryGirl.create(:lottery_code)
    @lottery = @lottery_code.lottery
    #@lottery = @lottery_code.lottery
    #@lottery_prize = FactoryGirl.create(:lottery_dsxl)
    @prize = FactoryGirl.create(:dsxl)
    # @user_bar = @lottery_code.user
	end

  test "should add a lottery code" do
  	
  	@lottery.add_lottery_code
    assert_not_nil !@lottery.lottery_codes[0].created_at
  end
  
  test "should give one lottery code to a user" do
    @lottery.give_lottery_code_to(@user_foo)
    assert true
  end

  test "should draw a lottery" do
    @lottery.prizes << @prize
    @lottery.save
    @prize.save
    assert_equal 0, @prize.status
    d = @lottery_code.draw
  end

  test "should make a interval" do
     
  end

end

