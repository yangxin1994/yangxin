require 'test_helper'

class Admin::AdvertisementsControllerTest < ActionController::TestCase
  
  test "01 should get index" do
		clear(Advertisement, User)

		get 'index', :format => :json
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::REQUIRE_LOGIN.to_s, result["value"]["error_code"]

		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 4
		user.role = 0
		user.save

		auth_key = sign_in(user.email, "123456")
		get 'index', :format => :json, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert_equal ErrorEnum::REQUIRE_ADMIN.to_s, result["value"]["error_code"]
		sign_out(auth_key)

		user = User.new(email: "test2@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 4
		user.role = 1
		user.save

		auth_key = sign_in(user.email, "123456")
		get 'index', :format => :json, :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval.count, 0
		sign_out(auth_key)

		clear(Advertisement, User)
	end
	
	test "02 should post create action with admin user login" do
		clear(User, Advertisement)

		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 4
		user.role = 1
		user.save
		
		auth_key = sign_in(user.email, "123456")
		post 'create', :advertisement => {title: "title1", linked: "linked1", image_location: "image_location1"}, :format => :json, :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval["linked"], "linked1"
		advertisement = Advertisement.all.first
		assert_equal advertisement.linked, "linked1"

		# unique
		post 'create', :advertisement => {title: "title1", linked: "linked1"}, :format => :json, :auth_key => auth_key
		assert_equal ErrorEnum::ADVERTISEMENT_SAVE_FAILED, JSON.parse(@response.body)["value"]

		# lack of image_location attr
		post 'create', :advertisement => {title: "title2", linked: "linked1"}, :format => :json, :auth_key => auth_key
		assert_equal ErrorEnum::ADVERTISEMENT_SAVE_FAILED, JSON.parse(@response.body)["value"]

		#
		# get index
		#
		post 'create', :advertisement => {title: "title2", linked: "linked1", image_location: "image_location1", activate: true}, :format => :json, :auth_key => auth_key
		post 'create', :advertisement => {title: "title3", linked: "linked1", image_location: "image_location1", activate: false}, :format => :json, :auth_key => auth_key

		assert_equal Advertisement.all.count, 3		

		# without ...
		get 'index', :format => :json, :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval.count, 3

		# with activate
		get 'index', :format => :json, :activate => true, :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval.count, Advertisement.activated.count

		get 'index', :format => :json, :activate => false, :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval.count, Advertisement.unactivate.count

		#with title
		get 'index', :format => :json, :title => "title1", :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval.count, 1

		get 'index', :format => :json, :title => "title2", :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval.count, 1

		#paging
		get 'index', :format => :json, :per_page => 2, :page => 2, :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval.count, 1

		sign_out(auth_key)
		
		#clear(User,Advertisement)
	end

	test "03 should post update action which is with admin " do
		clear(User, Advertisement)

		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 4
		user.role = 1
		user.save
		
		user2 = User.new(email: "test2@example.com", password: Encryption.encrypt_password("123456"))
		user2.status = 4
		user2.role = 1
		user2.save
	
		auth_key = sign_in(user.email, "123456")
		post 'create', :advertisement => {title: "title1", linked: "linked1", image_location: "image_location1"}, :format => :json, :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval["linked"], "linked1"
		advertisement = Advertisement.all.first
		assert_equal advertisement.linked, "linked1"
		sign_out(auth_key)
		
		# update with other user
		auth_key = sign_in(user2.email, "123456")

		advertisement = Advertisement.all.first

		post 'update', :id => "123443454354353", :advertisement => {linked: "updated linked1"}, :format => :json, :auth_key => auth_key
		retval = @response.body.to_i
		assert_equal ErrorEnum::ADVERTISEMENT_NOT_EXIST, JSON.parse(@response.body)["value"]

		post 'update', :id => advertisement.id.to_s, :advertisement => {linked: "updated linked1"}, :format => :json, :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]
		assert_equal retval["linked"], "updated linked1"

		assert_equal Advertisement.all.count, 1
		advertisement = Advertisement.all.first
		assert_equal advertisement.linked, "updated linked1"
		assert_equal advertisement.user, user2

		sign_out(auth_key)

		clear(User,Advertisement)
	end

	test "04 should destroy action which is with admin " do
		clear(User, Advertisement)

		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 4
		user.role = 1
		user.save
	
		auth_key = sign_in(user.email, "123456")

		post 'update', :id => "123443454354353", :format => :json, :auth_key => auth_key
		retval = @response.body.to_i
		assert_equal ErrorEnum::ADVERTISEMENT_NOT_EXIST, JSON.parse(@response.body)["value"]

		post 'create', :advertisement => {title: "title1", linked: "linked1", image_location: "image_location1"}, :format => :json, :auth_key => auth_key
		retval = JSON.parse(@response.body)["value"]

		post 'destroy', :id => retval["_id"], :format => :json, :auth_key => auth_key
		assert_equal JSON.parse(@response.body)["value"], true
		
		retval = Advertisement.where(_id: retval["_id"]).first
		assert_equal retval, nil
		sign_out(auth_key)

		clear(User,Advertisement)
	end

end
