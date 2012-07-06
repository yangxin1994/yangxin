require 'test_helper'

class PublicNoticesControllerTest < ActionController::TestCase

	test "00 init test db data. Everything action data format be JSON." do
		clear(User, PublicNotice)
		@@normal_user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		@@normal_user.status = 2
		@@normal_user.role = 0
		@@normal_user.save
		@@admin_user = User.new(email:"test2@example.com", password: Encryption.encrypt_password("123456"))
		@@admin_user.status = 2
		@@admin_user.role = 1
		@@admin_user.save
	end
	
	test "99 clear test db data" do 
		clear(User,PublicNotice)
	end 

	test "01 should get index action and no public_notice record" do
		get 'index', :format => :json
		assert_equal JSON.parse(@response.body), []		
	end
	
	test "02 should post create action which is without auth" do
		#sign_in(@@normal_user.email, Encryption.decrypt_password(@@normal_user.password))
		post 'create', :public_notice => {public_notice_type: "type1", title: "title1", content: "content1"}, :format => :json
		public_notice = JSON.parse(@response.body)
		assert_equal public_notice["title"], "title1"
		assert_equal public_notice["content"], "content1"
	end
	
	test "03 should get index action and has one public_notice record in 02 step" do
		public_notice = PublicNotice.where(public_notice_type: "type1").first
		get 'index', :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval[0]["title"], "title1"
	end
	
	test "04 should post update action which is without auth" do 
		public_notice = PublicNotice.where(public_notice_type: "type1").first
		if public_notice then
			assert_equal public_notice.title, "title1"
			post 'update', :id => public_notice.id.to_s, :public_notice => {title: "updated title1"}, :format => :json
			public_notice = PublicNotice.where(public_notice_type: "type1").first
			assert_equal public_notice["title"], "updated title1"
			assert_equal public_notice["content"], "content1"
		end
	end
	
	test "05 should get condition action which is without auth" do
		get 'condition', :key => "type", :value => "type1", :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval[0]["title"], "updated title1"

		get 'condition', :key => "title", :value => "title", :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval[0]["title"], "updated title1"
	end
	
	test "06 should delete destroy action which is without auth" do
		public_notice = PublicNotice.where(public_notice_type: "type1").first
		if public_notice then
			post 'destroy', :id => public_notice.id.to_s, :format => :json
			public_notice = PublicNotice.where(public_notice_type: "type1").first
			assert_equal public_notice, nil
		end
	end

end
