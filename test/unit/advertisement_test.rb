require 'test_helper'

class AdvertisementTest < ActiveSupport::TestCase

	test "01 find_by_id" do 
	  	clear(Advertisement)
	  	
		advertisement = Advertisement.create(title: "title1", linked: "linked1", image_location: "image_location1")
		assert_equal Advertisement.all.count, 1
		assert_equal Advertisement.find_by_id("4fff96616c6eea1204022005"), ErrorEnum::ADVERTISEMENT_NOT_EXIST
		assert_equal Advertisement.find_by_id(advertisement.id), advertisement

	  	clear(Advertisement)
	end

	test "02 list_by_title" do 
		clear(Advertisement)

		assert_equal Advertisement.list_by_title("sdfsdf"), []
		advertisement = Advertisement.create(title: "title1", linked: "linked1", image_location: "image_location1")
		advertisement2 = Advertisement.create(title: "title2", linked: "linked1", image_location: "image_location1")
		assert_equal Advertisement.all.count, 2
	  	assert_equal Advertisement.list_by_title(advertisement.title)[0], advertisement
	  	assert_equal Advertisement.list_by_title(advertisement2.title)[0], advertisement2

	  	clear(Advertisement)
	end

	test "03 create_advertisement" do 
		clear(Advertisement, User)

		user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.role = 1
		user.save

		advertisement = Advertisement.create_advertisement({title: "title1", linked: "linked1", image_location: "image_location1"}, user)
		assert_equal advertisement.user, user
		assert_equal advertisement.title, "title1"

		# unique
		assert_equal Advertisement.create_advertisement({title: "title1"}, user), ErrorEnum::ADVERTISEMENT_SAVE_FAILED
		# lack attr
		assert_equal Advertisement.create_advertisement({title: "title2"}, user), ErrorEnum::ADVERTISEMENT_SAVE_FAILED

		clear(Advertisement, User)
	end

	test "04 update_advertisement" do
		clear(User, Advertisement)
  	
		user = User.create(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user2 = User.create(email: "test2@example.com", password: Encryption.encrypt_password("123456"))
		
		advertisement = Advertisement.create_advertisement({title: "title1", linked: "linked1", image_location: "image_location1"}, user)
		assert_equal advertisement.user, user
		assert_equal advertisement.title, "title1"

		advertisement = Advertisement.update_advertisement(advertisement.id, {title: "updated title1", linked: "updated linked1"}, user2)		
		assert_equal advertisement.user, user2
		assert_equal advertisement.title, "updated title1"
		assert_equal advertisement.linked, "updated linked1"

		assert_equal Advertisement.all.count, 1

		advertisement = Advertisement.create_advertisement({title: "title2", linked: "linked2", image_location: "image_location2"}, user)

		assert_equal Advertisement.all.count, 2
		assert_equal Advertisement.list_by_title("updated title1").count, 1
		assert_equal Advertisement.update_advertisement(advertisement.id, {title: "updated title1"}, user), ErrorEnum::ADVERTISEMENT_SAVE_FAILED
	  	
	  	clear(User, Advertisement)
	end

	test "05 destroy_by_id " do
		
		clear(Advertisement)
		
		user = User.create(email: "test@example.com", password: Encryption.encrypt_password("123456"))

		advertisement = Advertisement.create_advertisement({title: "title1", linked: "linked1", image_location: "image_location1"}, user)
		assert_equal advertisement.user, user
		assert_equal advertisement.title, "title1"

		assert_equal Advertisement.destroy_by_id("4fff96616c6eea1204022005"), ErrorEnum::ADVERTISEMENT_NOT_EXIST
		assert_equal Advertisement.destroy_by_id(advertisement.id), true

		assert_equal Advertisement.all.count, 0
		
		clear(Advertisement)
		
	end

	test "06 activated and unactivate" do 
		clear(Advertisement)

		assert_equal Advertisement.all.desc(:updated_at), []
		advertisement = Advertisement.create(title: "title1", linked: "linked1", image_location: "image_location1", activate: true)
		advertisement2 = Advertisement.create(title: "title2", linked: "linked1", image_location: "image_location1", activate: false)
		assert_equal Advertisement.all.count, 2
		assert_equal Advertisement.activated.count, 1
	  	assert_equal Advertisement.activated[0], advertisement
	  	assert_equal Advertisement.unactivate.count, 1
	  	assert_equal Advertisement.unactivate[0], advertisement2


	  	clear(Advertisement)
	end

end
