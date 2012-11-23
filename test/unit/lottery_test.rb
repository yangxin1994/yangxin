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
    @prize1 = FactoryGirl.create(:dsxl_d)
    @prize1.weight = 100000
    @prize2 = FactoryGirl.create(:dsxl)
    @user_bar = @lottery_code.user
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
    @lottery.prizes << @prize2
    @lottery.save
    @prize.save
    # p @prize1.surplus
    d = @lottery_code.draw
    assert_equal 1, @prize.status
  end

  test "should draw a lottery and win" do
    @lottery.prizes << @prize1
    @lottery.save
    @prize1.save
    d = @lottery_code.draw
    assert_equal -1, @lottery_code.prize.status
  end

end

