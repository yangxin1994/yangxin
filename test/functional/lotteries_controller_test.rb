require 'test_helper'

class LotteriesControllerTest < ActionController::TestCase
  setup do
    @lottery = lotteries(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:lotteries)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create lottery" do
    assert_difference('Lottery.count') do
      post :create, lottery: @lottery.attributes
    end

    assert_redirected_to lottery_path(assigns(:lottery))
  end

  test "should show lottery" do
    get :show, id: @lottery.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @lottery.to_param
    assert_response :success
  end

  test "should update lottery" do
    put :update, id: @lottery.to_param, lottery: @lottery.attributes
    assert_redirected_to lottery_path(assigns(:lottery))
  end

  test "should destroy lottery" do
    assert_difference('Lottery.count', -1) do
      delete :destroy, id: @lottery.to_param
    end

    assert_redirected_to lotteries_path
  end
end
