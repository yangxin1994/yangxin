require 'test_helper'
class PointsControllerTest < ActionController::TestCase		
  setup do
    clear(User, PointLog)
    @admin_foo = FactoryGirl.create(:admin_foo)
    @user_bar = FactoryGirl.create(:user_bar)
    @auth_key = sign_in('admin_foo@gmail.com', '123123123')
  end


  test "should show a point log list " do
    get :index, :page => 1, :format => :json, :auth_key => @auth_key
    assert_response :success

   end
end