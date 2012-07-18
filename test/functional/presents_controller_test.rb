require 'test_helper'

class PresentsControllerTest < ActionController::TestCase
  # test "the truth" do
  #   assert true
  # end
  setup do
  	clear(User, Present)
  	@present = FactoryGirl.create(:present)
		@admin_bar = User.first
		@user_foo = User.last
  end

  test "show present list can be rewarded" do
  	get :index, :page => 1
  	assert_response :success
  	# get :index, :format => :json
  end


end
class Admin::PresentsControllerTest < ActionController::TestCase
  setup do
    clear(User, Present)
    @present = FactoryGirl.create(:present)
    @admin_bar = User.first
    @user_foo = User.last
  end
  
  test "sfdsdfdfdsfsfd" do
    get :expired, :page => 1, :format => :json
    assert_response :success
  end
end
