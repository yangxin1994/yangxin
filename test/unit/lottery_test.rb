require 'test_helper'

class LotteryTest < ActiveSupport::TestCase
	setup do
		clear(Award, Lottery, LotteryCode, User)
		#@lottery = FactoryGirl.create(:lottery)
    @lottery_code = FactoryGirl.create(:lottery_code)
    @lottery = @lottery_code.lottery
    #@lottery = @lottery_code.lottery
    #@lottery_award = FactoryGirl.create(:lottery_dsxl)
    @award = FactoryGirl.create(:dsxl)
    # @user_bar = @lottery_code.user
	end

  test "should add a lottery code" do
  	
  	@lottery.add_a_lottery_code
    assert_not_nil !@lottery.lottery_codes[0].created_at
  end
  
  test "should give one lottery code to a user" do
    @lottery.give_a_lottery_code_to(@user_foo)
    assert true
  end

  test "should draw a lottery" do
    @lottery.awards << @award
    @lottery.save
    @award.save
    assert_equal 0, @award.status
    d = @lottery_code.draw
  end

  test "should make a interval" do
     
  end

end

