require 'test_helper'

class AdvertisementsControllerTest < ActionController::TestCase

	test "01 should show info" do 
		clear(Advertisement)

		#create a advertisement
		ad = Advertisement.new(title: "title1", linked: "linked1", image_location: "image_location1")
		assert_equal ad.save, true

		#normal user can show advertisement item
		assert_equal Advertisement.all.count, 1
		advertisement = Advertisement.all.first

		get 'show', :format => :json, :id => advertisement.id.to_s
		retval = JSON.parse(@response.body)
		assert_equal retval["title"], "title1"
		assert_equal retval["_id"], advertisement.id.to_s

	end

end