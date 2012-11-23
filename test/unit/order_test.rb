class OrderTest < ActiveSupport::TestCase
  setup do
    clear(User, RewardLog, Order)
    #@ponit_log = FactoryGirl.create(:increase_point) 
    @jesse = init_jesse

  end

  test "should create a order for cash" do
    g = FactoryGirl.create(:rmb100)
    assert g.surplus == 10
    @jesse.update_attribute(:point, 1000)
    o = Order.create(:type => 0,
                 :gift => g,
                 :user => @jesse,
                 :is_update_user => true,
                 :full_name => "CASH",
                 :identity_card => "123123",
                 :bank => "cbc",
                 :bankcard_number => "alipay_account",
                 :phone => "123")

    @jesse.update
    g.update
    assert @jesse.full_name == "CASH"
    assert g.surplus == 9
    p @jesse.point
    assert @jesse.point == 500
  end

  test "should create a order for entity" do
    o = Order.create(:type => 1,
                 :user => @jesse,
                 :is_update_user => true,
                 :full_name => "CASH",
                 :address => "123123",
                 :postcode => "000000",
                 :phone => "123")

    @jesse.update
    assert @jesse.postcode == "000000"
  end

  test "should create a order for virtual" do
    g = FactoryGirl.create(:mobile100)
    o = Order.create(:type => 2,
                 :gift => g,
                 :user => @jesse,
                 :is_update_user => true,
                 :full_name => "CASH",
                 :phone => "1234")

    @jesse.update
    g.update
    assert @jesse.phone == "1234"
  end

  test "should create a order for lottery" do
    lc = @jesse.lottery_codes.count
    g = FactoryGirl.create(:lottery_gift)
    o = Order.create(:type => 3,
                 :gift => g,
                 :user => @jesse)

    @jesse.update
    g.update
    assert @jesse.lottery_codes.count == lc + 1
  end

end

