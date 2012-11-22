class OrdersControllerTest < ActionController::TestCase
  setup do
    clear(User, Order)
    @order = FactoryGirl.create(:order)
    @user_bar = User.first
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
    @order = Order.new
    post :create,
         :format => :json,
         :order => {:type => 1,
                    :status => 0,
                    :recipient => "Mazt",
                    :phone_number => "321464534",
                    :entity_receive_info =>{:address => "Matzs address",
                                               :post_code => "10000"
                    },
                    :user => @user_bar
         },
         :auth_key => @auth_key
    h = JSON.parse(@response.body)
    assert h["success"] == true
    assert !h["value"]["created_at"].nil?
  end

  test "should show a order" do

    get :show, :id => '123132', :auth_key => @auth_key
    h = JSON.parse(@response.body)

    assert h["success"] == false
    assert h["value"]["error_code"] == 21402
    #assert @response.body[]
    @user_bar.orders << @order
    @user_bar.save
    @order.save
    get :show, :id => @order.id, :auth_key => @auth_key
    h = JSON.parse(@response.body)

    assert h["success"] == true
    assert h["value"]["_id"] == "#{@order._id}"
    # assert_response :success
  end

end

