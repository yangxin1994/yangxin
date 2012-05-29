require 'test_helper'

class ResourceTest < ActiveSupport::TestCase
	test "resource creation" do
		clear(User, Resource)

		jesse = init_jesse

		retval = Resource.check_and_create_new("wrong email", 4, "location", "title")
		assert_equal ErrorEnum::EMAIL_NOT_EXIST, retval
		retval = Resource.check_and_create_new(jesse.email, 5, "location", "title")
		assert_equal ErrorEnum::WRONG_RESOURCE_TYPE, retval

		retval = Resource.check_and_create_new(jesse.email, 4, "location", "title")
		assert_equal jesse.email, retval["owner_email"]
		assert_equal "location", retval["location"]
		assert_equal "title", retval["title"]
		assert_equal 4, retval["resource_type"]
	end

	test "resource object list obtain" do
		clear(User, Resource)

		jesse = init_jesse
		oliver = init_oliver

		Resource.check_and_create_new(jesse.email, 4, "location1", "title1")
		Resource.check_and_create_new(jesse.email, 4, "location2", "title2")
		Resource.check_and_create_new(jesse.email, 4, "location3", "title3")
		Resource.check_and_create_new(jesse.email, 2, "location4", "title4")
		Resource.check_and_create_new(jesse.email, 2, "location5", "title5")
		Resource.check_and_create_new(jesse.email, 1, "location6", "title6")
		Resource.check_and_create_new(oliver.email, 4, "location7", "title7")
		Resource.check_and_create_new(oliver.email, 4, "location8", "title8")
		Resource.check_and_create_new(oliver.email, 4, "location9", "title9")

		retval = Resource.get_object_list(jesse.email, 7)
		assert_equal 6, retval.length
		
		retval = Resource.get_object_list(jesse.email, 5)
		assert_equal 4, retval.length

		retval = Resource.get_object_list(jesse.email, 3)
		assert_equal 3, retval.length
	end

	test "resource show" do
		clear(User, Resource)

		jesse = init_jesse

		retval = Resource.check_and_create_new(jesse.email, 4, "location", "title")
		resource_id = retval["resource_id"]

		retval = Resource.get_object(jesse.email, "wrong group id")
		assert_equal ErrorEnum::RESOURCE_NOT_EXIST, retval

		retval = Resource.get_object("wrong email", resource_id)
		assert_equal ErrorEnum::UNAUTHORIZED, retval

		retval = Resource.get_object(jesse.email, resource_id)
		assert_equal jesse.email, retval["owner_email"]
		assert_equal "location", retval["location"]
		assert_equal "title", retval["title"]
		assert_equal 4, retval["resource_type"]
	end

	test "resource delete" do
		clear(User, Resource)

		jesse = init_jesse

		retval = Resource.check_and_create_new(jesse.email, 4, "location", "title")
		resource_id = retval["resource_id"]

		resource_inst = Resource.find_by_id(resource_id)
		assert_equal Resource, resource_inst.class

		retval = resource_inst.delete("wrong email")
		assert_equal ErrorEnum::UNAUTHORIZED, retval

		retval = resource_inst.delete(jesse.email)
		assert_equal retval, true
		retval = Resource.get_object(jesse.email, resource_id)
		assert_equal ErrorEnum::RESOURCE_NOT_EXIST, retval
	end

	test "resource title update" do
		clear(User, Resource)

		jesse = init_jesse

		retval = Resource.check_and_create_new(jesse.email, 4, "location", "title")
		resource_id = retval["resource_id"]

		resource_inst = Resource.find_by_id(resource_id)
		assert_equal Resource, resource_inst.class

		retval = resource_inst.update_title("wrong email", "new_title")
		assert_equal ErrorEnum::UNAUTHORIZED, retval

		retval = resource_inst.update_title(jesse.email, "new_title")
		assert_equal true, retval
		retval = Resource.get_object(jesse.email, resource_id)
		assert_equal "new_title", retval["title"]
	end
end
