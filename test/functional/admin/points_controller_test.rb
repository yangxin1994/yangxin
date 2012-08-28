require 'test_helper'
class Admin::PointsControllerTest < ActionController::TestCase
  setup do
    clear(User, PointLog)
    @admin_foo = FactoryGirl.create(:admin_foo)
    @user_bar = FactoryGirl.create(:user_bar)
    @auth_key = sign_in('admin_foo@gmail.com', '123123123')
  end

  test "should add 100 point for user_bar" do

  # operate point success
    post :operate, :format => :json,
         :operate_point => 100,
         :user_id => @user_bar.id,
         :auth_key => @auth_key
    #pp re
    # pp PointLog.count
    # pp response.body
    @user_bar = User.find(@user_bar.id)
    assert_equal 100, PointLog.first.operated_point
    assert_equal 1100, @user_bar.point
  # operate point false with point type error
    post :operate, :format => :json,
         :operate_point => "f",
         :user_id => @user_bar.id,
         :auth_key => @auth_key
    #pp response.body
    assert_equal "{\"success\":false,\"value\":{\"error_code\":[21311],\"error_message\":{\"operated_point\":[\"is not a number\"]}}}", response.body
  # TODO operate point false without a user
    # post :operate, :format => :json,
    #      :operate_point => 100,
    #      :user_id => "sdfsfds"
    # pp response.body
    # assert_equal "{\"success\":false,\"value\":[21311]}", response.body
   
  end

end