class OrderTest < ActiveSupport::TestCase
  setup do
    #clear(User, RewardLog, Order)
    #@ponit_log = FactoryGirl.create(:increase_point) 
    @user_bar = FactoryGirl.create(:user_bar)

  end

  test "should create a order for cash" do
    g = FactoryGirl.create(:rmb100)
    assert g.surplus == 10
    @user_bar.update_attribute(:point, 1000)
    o = Order.create(:type => 0,
                 :gift => g,
                 :user => @user_bar,
                 :is_update_user => true,
                 :full_name => "CASH",
                 :identity_card => "123123",
                 :bank => "cbc",
                 :bankcard_number => "alipay_account",
                 :phone => "123")

    @user_bar.update
    g.update
    assert @user_bar.full_name == "CASH"
    assert g.surplus == 9
    #p @user_bar.point
    assert @user_bar.point == 500
  end

  test "should create a order for entity" do
    g = FactoryGirl.create(:kindle)
    o = Order.create(:type => 1,
                 :user => @user_bar,
                 :gift => g,
                 :is_update_user => true,
                 :full_name => "CASH",
                 :address => "123123",
                 :postcode => "000000",
                 :phone => "123")

    @user_bar.update
    g.update
    assert @user_bar.postcode == "000000"
  end

  test "should create a order for virtual" do
    g = FactoryGirl.create(:mobile100)
    o = Order.create(:type => 2,
                 :gift => g,
                 :user => @user_bar,
                 :is_update_user => true,
                 :full_name => "CASH",
                 :phone => "1234")

    @user_bar.update
    g.update
    assert @user_bar.phone == "1234"
  end

  test "should create a order for lottery" do
    lc = @user_bar.lottery_codes.count
    g = FactoryGirl.create(:lottery_gift)
    o = Order.create(:type => 3,
                 :gift => g,
                 :user => @user_bar)

    @user_bar.update
    g.update
    assert @user_bar.lottery_codes.count == lc + 1
  end

end

