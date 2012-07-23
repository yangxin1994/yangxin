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
    #sign_in admin_foo,Encryption.decrypt_password(123123123)
  end
  test "create a present" do
    @present = Present.new
    
    post :create,
         :format => :json,
         :present => {:name => '',
                      :type => 1,
                      :point => 4000,
                      :quantity => 20,
                      :description => 'bala bala',
                      :start_time => Time.now,
                      :end_time => Time.now.next_month,
                      :status => 1
          }
    assert_equal 'false', @response.body

    post :create,
         :format => :json,
         :present => {:name => 'new ipad',
                      :type => 1,
                      :point => 4000,
                      :quantity => 20,
                      :description => 'bala bala',
                      :start_time => Time.now,
                      :end_time => Time.now.next_month,
                      :status => 1
          }
    assert_not_equal 'false', @response.body

  end

  test "delete presents" do
    delete :delete,
           :format => :json,
           :ids => [@present.id,
                     "Yooooooooooooo",
                     Present.new.id ]
    assert_response :success
  end
  
  test "get expired presents" do
    get :expired, :page => 1, :format => :json
    assert_response :success
  end
end
