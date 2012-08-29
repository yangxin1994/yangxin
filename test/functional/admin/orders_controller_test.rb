require 'test_helper'
class Admin::OrdersControllerTest < ActionController::TestCase
  setup do
    clear(User, Order)
    3.times do
     @order = FactoryGirl.create(:order)
    end
    @user_foo = User.first
    @admin_foo = FactoryGirl.create(:admin_foo)
    @auth_key = sign_in('admin_foo@gmail.com', '123123123')
  end

  test "should show a order list" do
    list = [:index, :need_verify, :verified, :verify_failed, :delivering, :delivering, :delivered, :deliver_failed]
    list.each do |e|
      get e, :page => 1, :format => :json, :auth_key => @auth_key
      pp response.body
      # get e, :page => 1, :format => :xml, :auth_key => @auth_key
      # pp response.body
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