require 'test_helper'

class LotteryTest < ActiveSupport::TestCase
	setup do
		clear(Award, Lottery, LotteryCode, User, LotteryAward)
		@lottery = FactoryGirl.create(:lottery)
    @lottery_code = FactoryGirl.create(:lottery_code)
    #@lottery = @lottery_code.lottery
    #@lottery_award = FactoryGirl.create(:lottery_dsxl)
    @award = FactoryGirl.create(:dsxl)
    # @user_bar = @lottery_code.user
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
    @lottery_award = FactoryGirl.create(:lottery_dsxl)
    @lottery.lottery_awards << @lottery_award
    @lottery.save
    assert_equal 0, @lottery_award.status
    d = @lottery.draw(@lottery_code.id)
    p d
  end

  test "should make a interval" do
     
  end

end

