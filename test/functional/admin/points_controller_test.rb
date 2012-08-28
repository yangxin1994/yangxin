require 'test_helper'
class Admin::PointsControllerTest < ActionController::TestCase
  setup do
    clear(User, PointLog)
    @admin_foo = FactoryGirl.create(:admin_foo)
    @user_bar = FactoryGirl.create(:user_bar)
  end

  test "should add 100 point for user_bar" do

    auth_key = sign_in('admin_foo@gmail.com', '123123123')
    re = post :operate, :format => :json,
         :operate_point => 100,
         :user_id => @user_bar.id,
         :auth_key => auth_key
    #pp re
    pp PointLog.count
    @user_bar = User.find(@user_bar.id)
    assert_equal 100, PointLog.first.operated_point
    assert_equal 1100, @user_bar.point
  end

end