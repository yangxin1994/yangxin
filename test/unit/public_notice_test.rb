require 'test_helper'

class PublicNoticeTest < ActiveSupport::TestCase
	
	test "01 find_by_type" do
		
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
		
		PublicNotice.create(public_notice_type: 1, title: "title1", content: "content1")
		PublicNotice.create(public_notice_type: 2, title: "q2", content: "content2")
		
		assert_equal PublicNotice.find_by_type(0, "title").count, 1
		assert_equal PublicNotice.find_by_type(0, "content").count, 2
		assert_equal PublicNotice.find_by_type(1, "content").count, 1
		assert_equal PublicNotice.find_by_type(3, "content").count, 2
		
		clear(PublicNotice)
		
	end
	
end
