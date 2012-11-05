require 'test_helper'

class MessagesControllerTest < ActionController::TestCase
	setup do
		clear(Message, User)
		@user_bar = FactoryGirl.create(:user_bar)
		@user_bar.update_attribute(:last_read_messeges_time, Time.now - 1.day)
		@auth_key = sign_in('user_bar@gmail.com', '123123123')
		36.times{ FactoryGirl.create(:message) }
	end

	test "should show a messages list" do
		get :index, :format => :json, page: 3, per_page: 5, :auth_key => @auth_key
		pp @user_bar.unread_messages_count
		assert JSON.parse(response.body)["value"]["total_page"] == 8
		assert JSON.parse(response.body)["value"]["current_page"] == 3
		assert JSON.parse(response.body)["value"]["data"][0]["content"] == "hello"
		get :index, :format => :json, :auth_key => @auth_key
		assert JSON.parse(response.body)["value"]["total_page"] == 4
	end

	test "should show unread messages count" do
		get :unread_count, :format => :json, :auth_key => @auth_key
		#pp @user_bar.unread_messages_count
		#pp response.body
		assert_equal "{\"value\":36,\"success\":true}", response.body
	end 	
end
