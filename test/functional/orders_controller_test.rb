class OrdersControllerTest < ActionController::TestCase
  setup do
    @order = FactoryGirl.create(:order)
    @user_bar = FactoryGirl.create(:user_bar)
    @admin_foo = FactoryGirl.create(:admin_foo)
    @auth_key = sign_in('user_bar@gmail.com', '123123123')
  end

  test "should show a order list" do
    list = [:index, :for_cash, :for_entity, :for_virtual, :for_lottery]
    list.each do |e|
      get e, :page => 1, :format => :json, :auth_key => @auth_key
      h = JSON.parse(@response.body)
      assert_response :success
      assert h["success"] == true
    end
  end

  test "should create a new order" do
    # g = FactoryGirl.create(:kindle)
    # post :create,
    #      :format => :json,
    #      :order => {:type => 1,
    #                 :status => 0,
    #                 :is_update_user => true,
    #                 :full_name => "CASH",
    #                 :address => "123123",
    #                 :postcode => "000000",
    #                 :phone => "123",
    #                 :gift => g,
    #      },
    #      :auth_key => @auth_key
    # h = JSON.parse(@response.body)
    # p h
    # assert h["success"] == true
    # assert !h["value"]["created_at"].nil?
  end

  test "should show a order" do

    # get :show, :id => '123132', :auth_key => @auth_key
    # h = JSON.parse(@response.body)

    # assert h["success"] == false
    # assert h["value"]["error_code"] == 21402
    # #assert @response.body[]
    # @user_bar.orders << @order
    # @user_bar.save
    # @order.save
    # get :show, :id => @user_bar.orders[0]._id, :auth_key => @auth_key
    # h = JSON.parse(response.body)
    # p h
    # assert h["success"] == true
    # assert h["value"]["_id"] == "#{@order._id}"
    # assert_response :success
  end

end

