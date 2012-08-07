require 'test_helper'

class PublicNoticesControllerTest < ActionController::TestCase

	test "01 should get index action " do
		clear(PublicNotice)

		get 'index', :format => :json
		assert_equal JSON.parse(@response.body), []

		#create some public_notices for condition index
		f1 = PublicNotice.new(public_notice_type: 2, title: "title1", content: "content1")
		assert_equal f1.save, true
		f2 = PublicNotice.new(public_notice_type: 4, title: "title2", content: "content2")
		assert_equal f2.save, true
		f3 = PublicNotice.new(public_notice_type: 8, title: "title3", content: "content3")
		assert_equal f3.save, true
		f4 = PublicNotice.new(public_notice_type: 16, title: "title4", content: "content4")
		assert_equal f4.save, true

		assert_equal PublicNotice.all.count, 4

		# no type, no value
		get 'index', :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 4

		# with type, no value
		get 'index', :format => :json, :public_notice_type => 6
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 2

		get 'index', :format => :json, :public_notice_type => 255
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 4

		#with type and value
		get 'index', :format => :json, :public_notice_type => 6, :value => "content"
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 2

		get 'index', :format => :json, :public_notice_type => 6, :value => "content1"
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 1

		#paging
		get 'index', :format => :json, :per_page => 2
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 2

		get 'index', :format => :json, :per_page => 3, :page=> 2
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 1

		clear(PublicNotice)
	end

	test "02 should get show action" do
		clear(PublicNotice)

		f = PublicNotice.new(public_notice_type: 2, title: "title2", content: "content2")
		assert_equal f.save, true

		assert_equal PublicNotice.all.count, 1
		get "show", :format => :json, :id => f.id.to_s
		retval = JSON.parse(response.body)

		assert_equal retval["_id"], f.id.to_s
		assert_equal retval["public_notice_type"], 2
		assert_equal retval["title"], "title2"

		clear(PublicNotice)
	end

end
