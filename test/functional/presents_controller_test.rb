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

  test "should show some present list can be rewarded" do
    list = [:index, :virtualgoods, :cash, :realgoods, :stockout]
    list.each do |e|
      get e, :page => 1, :format => :json
      assert_response :success
    end
    # get :index, :format => :json
  end

  test "should show a present" do
    get :show,
        :id => @present.id,
        :format => :json
    assert @response.body
    get :show,
        :id => "Yooooooooooooo",
        :format => :json
    assert_equal "21002", @response.body
  end

  # test "" do

  # end

end

class Admin::PresentsControllerTest < ActionController::TestCase
  setup do
    clear(User, Present)
    @present = FactoryGirl.create(:present)
    @admin_bar = User.first
    @user_foo = User.last
    #sign_in admin_foo,Encryption.decrypt_password(123123123)
  end
  test "should create a present" do
    @present = Present.new
    
    post :create,
         :format => :json,
         :present => {:name => '',
                      :type => 1,
                      :point => 4000,
                      :quantity => 20,
                      :surplus => 10,
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
                      :surplus => 10,
                      :description => 'bala bala',
                      :start_time => Time.now,
                      :end_time => Time.now.next_month,
                      :status => 1
          }
    assert_not_equal 'false', @response.body

  end

  test "should delete some presents" do
    delete :delete,
           :format => :json,
           :ids => [@present.id,
                     "Yooooooooooooo",
                     Present.new.id ]
    assert_equal "[true,21002,21001]", @response.body
  end
  
end
