require 'test_helper'

class MessagesControllerTest < ActionController::TestCase
	setup do
		clear(Message, User)
		@user_bar = FactoryGirl.create(:user_bar)
		@user_bar.update_attribute(:last_read_messeges_time, Time.now - 1.day)
		@auth_key = sign_in('user_bar@gmail.com', '123123123')
		3.times{ FactoryGirl.create(:message) }
	end

	test "should show a messages list" do
		get :index, :format => :json, :auth_key => @auth_key
		pp @user_bar.unread_messages_count
		pp response.body
		assert response.body
	end

	test "should show unread messages count" do
		get :unread_count, :format => :json, :auth_key => @auth_key
		#pp @user_bar.unread_messages_count
		#pp response.body
		assert_equal "{\"success\":true,\"value\":3}", response.body
	end 	
end
