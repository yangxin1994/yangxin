require 'test_helper'

class PublicNoticeTest < ActiveSupport::TestCase
	
	test "01 public_notice_type= instance method" do
		
		clear(PublicNotice)
		
		assert_raise(TypeError) { 
			PublicNotice.create(public_notice_type: "type1", title: "title0", content: "content0") 
		}
		
		assert_raise(RangeError) { 
			PublicNotice.create(public_notice_type: 0, title: "title0", content: "content0") 
		}
		
		assert_raise(RangeError) { 
			PublicNotice.create(public_notice_type: 3, title: "title0", content: "content0") 
		}
		
		assert_raise(RangeError) { 
			PublicNotice.create(public_notice_type: 129, title: "title0", content: "content0") 
		}
		
		assert PublicNotice.create(public_notice_type: 1, title: "title1", content: "content1")
		assert PublicNotice.create(public_notice_type: 2, title: "q2", content: "content2")
		
		clear(PublicNotice)
		
	end

	test "02 test rewrite instance method: save" do 
	  	clear(User, PublicNotice)
	  	
		# origin save method must be work which is without user 
		public_notice = PublicNotice.new(public_notice_type: 1, title: "title1", content: "content1")
		assert public_notice.save
		assert_equal public_notice.user_id, nil
	  	
	  	# new save method must be work which is with user
	  	user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 1
		user.save
		
		public_notice = PublicNotice.new(public_notice_type: 1, title: "title2", content: "content2")
		assert public_notice.save(user)
		assert_equal public_notice.user, user
	  	
	  	clear(User, PublicNotice)
	end
	  
	test "03 test rewrite instance method: update_attributes" do
		clear(User, PublicNotice)
  	
		public_notice = PublicNotice.new(public_notice_type: 1, title: "title1", content: "content1")
		assert public_notice.save
		
		# origin update_attributes method must be work which is without user 
		assert public_notice.update_attributes({title: "updated title1"})
		assert_equal public_notice.title, "updated title1"
	  	
	  	# new update_attributes method must be work which is with user
	  	user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 1
		user.save
		
		assert public_notice.update_attributes({title: "updated updated title1"}, user)	
		assert_equal public_notice.user, user
		assert_equal public_notice.title, "updated updated title1"
	  	
	  	clear(User, PublicNotice)
	end

	test "04 condition " do
		
		clear(PublicNotice)
		
		PublicNotice.create(public_notice_type: 1, title: "title1", content: "content1")
		PublicNotice.create(public_notice_type: 2, title: "q2", content: "content2")

		assert_raise(TypeError){
			PublicNotice.condition("type1", "")
		}

		assert_raise(RangeError){
			PublicNotice.condition(-1, "")
		}

		assert_raise(ArgumentError){
			PublicNotice.condition(4, "")
		}
		
		assert_equal PublicNotice.condition(0, "title").count, 0
		assert_equal PublicNotice.condition(0, "content").count, 0
		assert_equal PublicNotice.condition(1, "content").count, 1
		assert_equal PublicNotice.condition(3, "content").count, 2
		
		clear(PublicNotice)
		
	end
	
	test "05 find_by_type" do 
		clear(PublicNotice)

		PublicNotice.create(public_notice_type: 1, title: "title1", content: "content1")
		PublicNotice.create(public_notice_type: 2, title: "q2", content: "content2")

		assert_raise(TypeError){
			PublicNotice.find_by_type("type1")
		}

		assert_raise(RangeError){
			PublicNotice.find_by_type(256)
		}
		
		assert_equal PublicNotice.find_by_type(0).count, 0
		assert_equal PublicNotice.find_by_type(1).count, 1
		assert_equal PublicNotice.find_by_type(2).count, 1
		assert_equal PublicNotice.find_by_type(3).count, 2
		assert_equal PublicNotice.find_by_type(255).count, 2

		clear(PublicNotice)
	end
	
end
