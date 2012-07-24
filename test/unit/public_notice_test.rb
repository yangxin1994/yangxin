require 'test_helper'

class PublicNoticeTest < ActiveSupport::TestCase
	
	test "01 verify_public_notice_type method" do 
		clear(PublicNotice)
		
		assert_equal PublicNotice.verify_public_notice_type("type1"), ErrorEnum::PUBLIC_NOTICE_TYPE_ERROR
		assert_equal PublicNotice.verify_public_notice_type(0), ErrorEnum::PUBLIC_NOTICE_RANGE_ERROR
		assert_equal PublicNotice.verify_public_notice_type(1), true
		assert_equal PublicNotice.verify_public_notice_type(129), ErrorEnum::PUBLIC_NOTICE_RANGE_ERROR

		clear(PublicNotice)
	end

	test "02 find_by_id" do 
	  	clear(PublicNotice)
	  	
		public_notice = PublicNotice.create(public_notice_type: 1, title: "title1", content: "content1")
		assert_equal PublicNotice.find_by_id("4fff96616c6eea1204022005"), ErrorEnum::PUBLIC_NOTICE_NOT_EXIST
		assert_equal PublicNotice.find_by_id(public_notice.id), public_notice
	  	
	  	clear(PublicNotice)
	end

	test "03 create_public_notice" do 
		clear(PublicNotice, User)

		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.save

		public_notice = PublicNotice.create_public_notice({public_notice_type: 1, title: "title1", content: "content1"}, user)
		assert_equal public_notice.user, user
		assert_equal public_notice.title, "title1"
		assert_equal public_notice.public_notice_type, 1

		assert_equal PublicNotice.create_public_notice({public_notice_type: "type1", title: "title1"}, user), ErrorEnum::PUBLIC_NOTICE_TYPE_ERROR
		assert_equal PublicNotice.create_public_notice({public_notice_type: 0, title: "title1"}, user), ErrorEnum::PUBLIC_NOTICE_RANGE_ERROR
		assert_equal PublicNotice.create_public_notice({public_notice_type: 129, title: "title1"}, user), ErrorEnum::PUBLIC_NOTICE_RANGE_ERROR

		clear(PublicNotice, User)
	end

	test "04 update_public_notice" do
		clear(User, PublicNotice)
  	
		user = User.create(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user2 = User.create(email: "test2@example.com", password: Encryption.encrypt_password("123456"))
		
		public_notice = PublicNotice.create_public_notice({public_notice_type: 1, title: "title1", content: "content1"}, user)
		assert_equal public_notice.user, user
		assert_equal public_notice.title, "title1"
		assert_equal public_notice.public_notice_type, 1

		public_notice = PublicNotice.update_public_notice(public_notice.id, {public_notice_type: 2, title: "updated title1", content: "updated content1"}, user2)		
		assert_equal public_notice.user, user2
		assert_equal public_notice.title, "updated title1"
		assert_equal public_notice.public_notice_type, 2

		assert_equal PublicNotice.update_public_notice(public_notice.id,{public_notice_type: "type1", title: "title1"}, user), ErrorEnum::PUBLIC_NOTICE_TYPE_ERROR
		assert_equal PublicNotice.update_public_notice(public_notice.id,{public_notice_type: 0, title: "title1"}, user), ErrorEnum::PUBLIC_NOTICE_RANGE_ERROR
		assert_equal PublicNotice.update_public_notice(public_notice.id,{public_notice_type: 129, title: "title1"}, user), ErrorEnum::PUBLIC_NOTICE_RANGE_ERROR

		assert_equal PublicNotice.all.count, 1
	  	
	  	clear(User, PublicNotice)
	end

	test "05 destroy_by_id " do
		
		clear(PublicNotice)
		
		user = User.create(email: "test@example.com", password: Encryption.encrypt_password("123456"))

		public_notice = PublicNotice.create_public_notice({public_notice_type: 1, title: "title1", content: "content1"}, user)
		assert_equal public_notice.user, user
		assert_equal public_notice.title, "title1"
		assert_equal public_notice.public_notice_type, 1

		assert_equal PublicNotice.destroy_by_id("4fff96616c6eea1204022005"), ErrorEnum::PUBLIC_NOTICE_NOT_EXIST
		assert_equal PublicNotice.destroy_by_id(public_notice.id), true
		
		clear(PublicNotice)
		
	end

	test "06 list_by_type" do 
		clear(PublicNotice)

		user = User.create(email: "test@example.com", password: Encryption.encrypt_password("123456"))

		PublicNotice.create_public_notice({public_notice_type: 1, title: "title1", content: "content1"}, user)
		PublicNotice.create_public_notice({public_notice_type: 2, title: "title1", content: "content1"}, user)
		PublicNotice.create_public_notice({public_notice_type: 4, title: "title1", content: "content1"}, user)
		PublicNotice.create_public_notice({public_notice_type: 8, title: "title1", content: "content1"}, user)
		PublicNotice.create_public_notice({public_notice_type: 16, title: "title1", content: "content1"}, user)
		PublicNotice.create_public_notice({public_notice_type: 32, title: "title1", content: "content1"}, user)
		PublicNotice.create_public_notice({public_notice_type: 64, title: "title1", content: "content1"}, user)
		PublicNotice.create_public_notice({public_notice_type: 128, title: "title1", content: "content1"}, user)

		assert_equal PublicNotice.all.count, 8
		assert_equal PublicNotice.list_by_type(1).count, 1
		assert_equal PublicNotice.list_by_type(4).count, 1
		assert_equal PublicNotice.list_by_type(16).count, 1
		assert_equal PublicNotice.list_by_type(64).count, 1
		assert_equal PublicNotice.list_by_type(7).count, 3
		assert_equal PublicNotice.list_by_type(255).count, 8

		clear(PublicNotice)
	end

	test "07 list_by_type_and_value" do 
		clear(PublicNotice)

		user = User.create(email: "test@example.com", password: Encryption.encrypt_password("123456"))

		PublicNotice.create_public_notice({public_notice_type: 1, title: "title1", content: "content1"}, user)
		PublicNotice.create_public_notice({public_notice_type: 1, title: "title2", content: "content2"}, user)
		PublicNotice.create_public_notice({public_notice_type: 2, title: "title1", content: "content1"}, user)
		PublicNotice.create_public_notice({public_notice_type: 4, title: "title1", content: "content1"}, user)
		PublicNotice.create_public_notice({public_notice_type: 8, title: "title1", content: "content1"}, user)
		PublicNotice.create_public_notice({public_notice_type: 16, title: "title1", content: "content1"}, user)
		PublicNotice.create_public_notice({public_notice_type: 32, title: "title1", content: "content1"}, user)
		PublicNotice.create_public_notice({public_notice_type: 64, title: "title1", content: "content1"}, user)
		PublicNotice.create_public_notice({public_notice_type: 128, title: "title1", content: "content1"}, user)

		assert_equal PublicNotice.all.count, 9
		assert_equal PublicNotice.list_by_type_and_value(1, nil).count, 2
		assert_equal PublicNotice.list_by_type_and_value(1, "content1").count, 1
		assert_equal PublicNotice.list_by_type_and_value(1, "title1").count, 1
		assert_equal PublicNotice.list_by_type_and_value(255, "title").count, 9
		assert_equal PublicNotice.list_by_type_and_value(255, "title1").count, 8

		clear(PublicNotice)
	end
	
end
