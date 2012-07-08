require 'test_helper'

class PublicNoticeTest < ActiveSupport::TestCase
  
  test "00 init test db data" do
		clear(User, PublicNotice)
		@@normal_user = User.new(email: "test@example.com")
		@@normal_user.role = 0
		@@normal_user.save
		@@admin_user = User.new(email:"test2@example.com")
		@@admin_user.role = 1
		@@admin_user.save
		@@admin_user3 = User.new(email:"test3@example.com")
		@@admin_user3.role = 1
		@@admin_user3.save		
	end
	
	test "99 clear test db data" do 
		clear(User, PublicNotice)
	end 

	test "01 a normal user create new public_notice from method: create_by_user" do
		if @@normal_user then
			assert !PublicNotice.create_by_user(@@normal_user, "type1", "title1", "content1")
		end
	end
   
	test "02 a admin user create new public_notice from method: create_by_user" do
		if @@admin_user then
			assert PublicNotice.create_by_user(@@admin_user, "type2", "title2", "content2")
		end
	end

	test "03 a admin user update public_notice from method: update_by_user" do
		public_notice = PublicNotice.where(public_notice_type: "type2").first
		if @@admin_user3 and public_notice then
			assert PublicNotice.update_by_user(public_notice.id, @@admin_user3, {title: "updated title22"})
			assert PublicNotice.where(public_notice_type: "type2").first.user.id.to_s == @@admin_user3.id.to_s
		end 
		if @@admin_user and public_notice then
			assert PublicNotice.update_by_user(public_notice.id, @@admin_user, {title: "updated title2"})
			assert PublicNotice.where(public_notice_type: "type2").first.title.to_s == "updated title2"
		end
	end
	
	test "04 a admin user get public_notices with condition from method: condition" do
		public_notice = PublicNotice.condition("type", "type2").first
  	assert_equal public_notice.title, "updated title2"
    public_notice = PublicNotice.condition("title", "updated title2").first
    assert_equal public_notice.title, "updated title2"
	end

	test "05 a admin user destroy public_notice from method: destroy_by_user" do
		public_notice = PublicNotice.where(public_notice_type: "type2").first
		if @@admin_user and public_notice then
			assert PublicNotice.destroy_by_user(public_notice.id, @@admin_user)
		end
	end
  
end
