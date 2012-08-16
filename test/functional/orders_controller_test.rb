# encoding: utf-8
require 'test_helper'

class OrdersControllerTest < ActionController::TestCase
  setup do
    clear(User, Order)
    @order = FactoryGirl.create(:order)
    @user_bar = User.first
    @admin_foo = FactoryGirl.create(:admin_foo)
  end

  test "should show a order list" do
    list = [:index, :for_cash, :for_realgoods, :for_virtualgoods, :for_lottery]
    list.each do |e|
      get e, :page => 1, :format => :json
      assert_response :success
    end
  end

  test "should create a new order" do
    @order = Order.new
    post :create,
         :format => :json,
         :order => {:type => 1,
                    :status => 0,
                    :recipient => "Mazt",
                    :phone_number => "321464534",
                    :realgoods_receive_info =>{:address => "Matzs address",
                                               :post_code => "10000"
                    },
                    :user => @user_bar
         }
    #p @response.body
    assert_not_nil @response.body
  end
end

