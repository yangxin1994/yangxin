require 'test_helper'

class Admin::AdvertisementsControllerTest < ActionController::TestCase
  
  test "01 should get index" do
		clear(Advertisement, User)

		get 'index', :format => :json
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::REQUIRE_LOGIN.to_s, result["value"]["error_code"]

		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 0
		user.save

		sign_in(user.email, "123456")
		get 'index', :format => :json
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::REQUIRE_ADMIN.to_s, result["value"]["error_code"]
		sign_out

		user = User.new(email: "test2@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 1
		user.save

		sign_in(user.email, "123456")
		get 'index', :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 0
		sign_out

		clear(Advertisement, User)
	end
	
	test "02 should post create action with admin user login" do
		clear(User, Advertisement)

		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 1
		user.save
		
		sign_in(user.email, "123456")
		post 'create', :advertisement => {title: "title1", linked: "linked1", image_location: "image_location1"}, :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval["linked"], "linked1"
		advertisement = Advertisement.all.first
		assert_equal advertisement.linked, "linked1"

		# unique
		post 'create', :advertisement => {title: "title1", linked: "linked1"}, :format => :json
		assert_equal ErrorEnum::ADVERTISEMENT_SAVE_FAILED.to_s, @response.body

		# lack of image_location attr
		post 'create', :advertisement => {title: "title2", linked: "linked1"}, :format => :json
		assert_equal ErrorEnum::ADVERTISEMENT_SAVE_FAILED.to_s, @response.body

		#
		# get index
		#
		post 'create', :advertisement => {title: "title2", linked: "linked1", image_location: "image_location1", activate: true}, :format => :json
		post 'create', :advertisement => {title: "title3", linked: "linked1", image_location: "image_location1", activate: false}, :format => :json

		assert_equal Advertisement.all.count, 3		

		# without ...
		get 'index', :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 3

		# with activate
		get 'index', :format => :json, :activate => true
		retval = JSON.parse(@response.body)
		assert_equal retval.count, Advertisement.activated.count

		get 'index', :format => :json, :activate => false
		retval = JSON.parse(@response.body)
		assert_equal retval.count, Advertisement.unactivate.count

		#with title
		get 'index', :format => :json, :title => "title1"
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 1

		get 'index', :format => :json, :title => "title2"
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 1

		#paging
		get 'index', :format => :json, :per_page => 2, :page => 2
		retval = JSON.parse(@response.body)
		assert_equal retval.count, 1

		sign_out
		
		#clear(User,Advertisement)
	end

	test "03 should post update action which is with admin " do
		clear(User, Advertisement)

		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 1
		user.save
		
		user2 = User.new(email: "test2@example.com", password: Encryption.encrypt_password("123456"))
		user2.status = 2
		user2.role = 1
		user2.save
	
		sign_in(user.email, "123456")
		post 'create', :advertisement => {title: "title1", linked: "linked1", image_location: "image_location1"}, :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval["linked"], "linked1"
		advertisement = Advertisement.all.first
		assert_equal advertisement.linked, "linked1"
		sign_out
		
		# update with other user
		sign_in(user2.email, "123456")

		advertisement = Advertisement.all.first

		post 'update', :id => "123443454354353", :advertisement => {linked: "updated linked1"}, :format => :json
		retval = @response.body.to_i
		assert_equal ErrorEnum::ADVERTISEMENT_NOT_EXIST.to_s, @response.body

		post 'update', :id => advertisement.id.to_s, :advertisement => {linked: "updated linked1"}, :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval["linked"], "updated linked1"

		assert_equal Advertisement.all.count, 1
		advertisement = Advertisement.all.first
		assert_equal advertisement.linked, "updated linked1"
		assert_equal advertisement.user, user2

		sign_out

		clear(User,Advertisement)
	end

	test "04 should destroy action which is with admin " do
		clear(User, Advertisement)

		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 1
		user.save
	
		sign_in(user.email, "123456")

		post 'update', :id => "123443454354353", :format => :json
		retval = @response.body.to_i
		assert_equal ErrorEnum::ADVERTISEMENT_NOT_EXIST.to_s, @response.body

		post 'create', :advertisement => {title: "title1", linked: "linked1", image_location: "image_location1"}, :format => :json
		retval = JSON.parse(@response.body)

		post 'destroy', :id => retval["_id"], :format => :json
		assert_equal @response.body, "true"
		
		retval = Advertisement.where(_id: retval["_id"]).first
		assert_equal retval, nil
		sign_out

		clear(User,Advertisement)
	end

end
