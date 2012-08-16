class Admin::OrdersControllerTest < ActionController::TestCase
  setup do
    clear(User, Order)
    #@order = FactoryGirl.create(:order)
    @user_foo = User.first
    @admin_foo = FactoryGirl.create(:admin_foo)   
  end

  test "should show a order list" do
    list = [:index, :need_verify, :verified, :verify_failed, :delivering, :delivering, :delivered, :deliver_failed]
    list.each do |e|
      get e, :page => 1, :format => :json
      assert_response :success
    end
  end
  
  # test "should delete some orders" do
  #   delete :delete,
  #          :format => :json,
  #          :ids => [@order.id,
  #                    "Yooooooooooooo",
  #                    Order.new.id ]
  #   assert_equal "[true,21002,21001]", @response.body
  # end

end