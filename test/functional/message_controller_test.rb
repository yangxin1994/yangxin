require 'test_helper'

class MessagesControllerTest < ActionController::TestCase
	setup do
		@message = messages(:one)
	end

	test "should get index" do
		clear(User, Message)
		jesse = init_jesse
		oliver = init_oliver
		lisa = init_lisa
		set_as_admin(jesse)
		 
		message_id_1 = *Message.create_new("title1", "content1", jesse._id, 0, [])
		message_id_2 = *Message.create_new("title2", "content2", jesse._id, 1, [oliver._id])
		message_id_3 = *Message.create_new("title3", "content3", jesse._id, 1, [oliver._id])
		message_id_4 = *Message.create_new("title4", "content4", jesse._id, 0, [])
		message_id_5 = *Message.create_new("title5", "content5", jesse._id, 1, [lisa._id])
		message_id_6 = *Message.create_new("title6", "content6", jesse._id, 1, [lisa._id])
		message_id_7 = *Message.create_new("title7", "content7", jesse._id, 1, [oliver._id, lisa._id])
		message_id_8 = *Message.create_new("title8", "content8", jesse._id, 1, [oliver._id, lisa._id])

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :index, :format => :json, :user_id = "jienghdo03uu044"
		assert_equal ErrorEnum::USER_NOT_EXIST.to_s, @response.body
		sign_out
		
		sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		get :index, :format => :json, :user_id = oliver._id
		message_obj_list = JSON.parse(@response.body)
		assert_equal 6, message_obj_list.size
		assert message_obj_list.map{ |message_obj| message_obj["_id"] }.include?(message_id_1)
		assert message_obj_list.map{ |message_obj| message_obj["_id"] }.include?(message_id_2)
		assert message_obj_list.map{ |message_obj| message_obj["_id"] }.include?(message_id_3)
		assert message_obj_list.map{ |message_obj| message_obj["_id"] }.include?(message_id_4)
		assert message_obj_list.map{ |message_obj| message_obj["_id"] }.include?(message_id_7)
		assert message_obj_list.map{ |message_obj| message_obj["_id"] }.include?(message_id_8)
		sign_out
		
		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :index, :format => :json, :user_id = ""
		message_obj_list = JSON.parse(@response.body)
		assert_equal 8, message_obj_list.size
		assert message_obj_list.map{ |message_obj| message_obj["_id"] }.include?(message_id_1)
		assert message_obj_list.map{ |message_obj| message_obj["_id"] }.include?(message_id_2)
		assert message_obj_list.map{ |message_obj| message_obj["_id"] }.include?(message_id_3)
		assert message_obj_list.map{ |message_obj| message_obj["_id"] }.include?(message_id_4)
		assert message_obj_list.map{ |message_obj| message_obj["_id"] }.include?(message_id_5)
		assert message_obj_list.map{ |message_obj| message_obj["_id"] }.include?(message_id_6)
		assert message_obj_list.map{ |message_obj| message_obj["_id"] }.include?(message_id_7)
		assert message_obj_list.map{ |message_obj| message_obj["_id"] }.include?(message_id_8)
		sign_out
		
		
	end

	test "should show message" do
		clear(User, Message)
		jesse = init_jesse
		oliver = init_oliver
		lisa = init_lisa
		set_as_admin(jesse)
		
		message_id_1 = *Message.create_new("title1", "content1", jesse._id, 0, [])
		message_id_2 = *Message.create_new("title2", "content2", jesse._id, 1, [oliver._id])
		message_id_3 = *Message.create_new("title3", "content3", jesse._id, 1, [oliver._id])
		message_id_4 = *Message.create_new("title4", "content4", jesse._id, 0, [])
		message_id_5 = *Message.create_new("title5", "content5", jesse._id, 1, [lisa._id])
		message_id_6 = *Message.create_new("title6", "content6", jesse._id, 1, [lisa._id])
		message_id_7 = *Message.create_new("title7", "content7", jesse._id, 1, [oliver._id, lisa._id])
		message_id_8 = *Message.create_new("title8", "content8", jesse._id, 1, [oliver._id, lisa._id])

		sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		get :show, :format => :json, :user_id => oliver._id, :message_id => message_id_1
		assert_equal ErrorEnum::UNAUTHORIZED.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :show, :format => :json, :user_id => jesse._id, :message_id => "wrong message id"
		assert_equal ErrorEnum::MESSAGE_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :show, :format => :json, :user_id => jesse._id, :message_id => message_id_4
		message_obj = JSON.parse(@response.body)
		assert_equal "title4", message_obj["title"]
		assert_equal "content4", message_obj["content"]
		assert_equal 0, message_obj["message_type"]
		sign_out
	end

	test "should create message" do
		clear(User, Message)
		jesse = init_jesse
		oliver = init_oliver
		set_as_admin(jesse)

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :title => "", :content => "1content", :sender_id => jesse._id, :type => 0, :receiver_ids => [] 
		assert_equal ErrorEnum::TITLE_CAN_NOT_BLANK.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :title => "1title", :content => "", :sender_id => jesse._id, :type => 0, :receiver_ids => [] 
		assert_equal ErrorEnum::CONTENT_CAN_NOT_BLANK.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :title => "1title", :content => "1content", :sender_id => jesse._id, :type => 1, :receiver_ids => [] 
		assert_equal ErrorEnum::RECIVER_CAN_NOT_BLANK.to_s, @response.body
		sign_out

		sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		post :create, :format => :json, :title => "", :content => "1content", :sender_id => jesse._id, :type => 0, :receiver_ids => [] 
		assert_equal ErrorEnum::UNTHROZIED.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :title => "1title", :content => "1content", :sender_id => jesse._id, :type => 1, :receiver_ids => ["wrong receiver id", oliver._id] 
		assert_equal ErrorEnum::THERE_ARE_SOME_RECEIVERS_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		post :create, :format => :json, :title => "1title", :content => "1content", :sender_id => jesse._id, :type => 0, :receiver_ids => []
		message_obj = JSON.parse(@response.body)
		assert_equal "1title", message_obj["title"]
		assert_equal "1content", message_obj["content"]
		assert_equal jesse._id, message_obj["sender_id"]
		assert_equal 0, message_obj["type"]
		sign_out
	end

	test "should get edit" do
		get :edit, id: @message.to_param
		assert_response :success
	end

	test "should update message" do
		clear(User, Message)
		jesse = init_jesse
		oliver = init_oliver
		set_as_admin(jesse)

		message_id_1 = *Message.create_new("title1", "content1", jesse._id, 0, [])
		message_id_2 = *Message.create_new("title2", "content2", jesse._id, 1, [oliver._id])

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :show, :format => :json, :message_id => message_id_1
		message_obj = JSON.parse(@response.body)
		message_obj["title"] ="new title"
		put :update, :format => :json, :message => message_obj, :message_id = message_id_1
		message_obj1 = JSON.parse(@response.body)
		assert_equal "new title", message_obj1["title"]	
		sign_out

		sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		put :update, :format => :json, :message => message_obj, :message_id = message_id_2
		assert_equal ErrorEnum::REQUIRE_ADMIN.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :message => message_obj, :message_id = "wrong message id"
		assert_equal ErrorEnum::MESSAGE_NOT_EXIST.to_s, @response.body
		sign_out
	end

	test "should destroy message" do
		clear(User, Messasge)
		jesse = init_jesse
		oliver = init_oliver
		set_as_admin(jesse)

		message_id_1 = *Message.create_new("title1", "content1", jesse._id, 0, [])
		message_id_2 = *Message.create_new("title2", "content2", jesse._id, 1, [oliver._id])

		sign_in(oliver.email, Encryption.decrypt_password(oliver.password))
		delete :destroy, :format => :json, :message_id => message_id_1
		assert_equal ErrorEnum::REQUIRE_ADMIN.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :message_id => "wrong_message_id"
		assert_equal ErrorEnum::MESSAGE_NOT_EXIST.to_s, @response.body
		sign_out

		sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		delete :destroy, :format => :json, :message_id => message_id_1
		assert_equal true.to_s, @response.body
		get :show, :format => :json, :message_id => message_id_1
		assert_equal ErrorEnum::MESSAGE_NOT_EXIST.to_s, @response.body
		sign_out
	end

	test "get number of unlooked messages" do
		clear(User, Messasge)
		jesse = init_jesse
		oliver = init_oliver
		set_as_admin(jesse)

		sign_in(oliver.email, Encryption.decrypt_password(oliver.password)	
		message_id_1 = *Message.create_new("title1", "connt1", jesse._id, 0, [])
		message_id_2 = *Message.create_new("title2", "content2", jesse._id, 1, [oliver._id])
		get :get_number_unlooked, :format => :json, :user_id = oliver._id, :last_visit_time = oliver.last_visit_time
		assert_equal "2", @response.body
		get :index, :format => :json, :user_id = oliver._id
		get :get_number_unlooked, :format => :json, :user_id = oliver._id
		assert_equal "0", @response.body
		message_id_3 = *Message.create_new("title3", "content3", jesse._id, 1, [oliver._id])
		get :get_number_unlooked, :format => :json, :user_id = oliver._id, :last_visit_time = oliver.last_visit_time
		assert_equal "1", @response.body
		sign_out

		sign_in(oliver.email, Encryption.decrypt_password(oliver.password)
		get :get_number_unlooked, :format => :json, :user_id = "wrong user id", :last_visit_time = oliver.last_visit_time
		assert_equal ErrorEnum::USER_NOT_EXIST.to_s, @response.body
		sign_out
	end
end
