require 'test_helper'

class MaterialTest < ActiveSupport::TestCase
	test "material creation" do
		clear(User, Material)

		jesse = init_jesse

		retval = Material.check_and_create_new("wrong email", 4, "location", "title")
		assert_equal ErrorEnum::EMAIL_NOT_EXIST, retval
		retval = Material.check_and_create_new(jesse.email, 5, "location", "title")
		assert_equal ErrorEnum::WRONG_MATERIAL_TYPE, retval

		retval = Material.check_and_create_new(jesse.email, 4, "location", "title")
		assert_equal jesse.email, retval["owner_email"]
		assert_equal "location", retval["location"]
		assert_equal "title", retval["title"]
		assert_equal 4, retval["material_type"]
	end

	test "material object list obtain" do
		clear(User, Material)

		jesse = init_jesse
		oliver = init_oliver

		Material.check_and_create_new(jesse.email, 4, "location1", "title1")
		Material.check_and_create_new(jesse.email, 4, "location2", "title2")
		Material.check_and_create_new(jesse.email, 4, "location3", "title3")
		Material.check_and_create_new(jesse.email, 2, "location4", "title4")
		Material.check_and_create_new(jesse.email, 2, "location5", "title5")
		Material.check_and_create_new(jesse.email, 1, "location6", "title6")
		Material.check_and_create_new(oliver.email, 4, "location7", "title7")
		Material.check_and_create_new(oliver.email, 4, "location8", "title8")
		Material.check_and_create_new(oliver.email, 4, "location9", "title9")

		retval = Material.get_object_list(jesse.email, 7)
		assert_equal 6, retval.length
		
		retval = Material.get_object_list(jesse.email, 5)
		assert_equal 4, retval.length

		retval = Material.get_object_list(jesse.email, 3)
		assert_equal 3, retval.length
	end

	test "material show" do
		clear(User, Material)

		jesse = init_jesse

		retval = Material.check_and_create_new(jesse.email, 4, "location", "title")
		material_id = retval["material_id"]

		retval = Material.get_object(jesse.email, "wrong group id")
		assert_equal ErrorEnum::MATERIAL_NOT_EXIST, retval

		retval = Material.get_object("wrong email", material_id)
		assert_equal ErrorEnum::UNAUTHORIZED, retval

		retval = Material.get_object(jesse.email, material_id)
		assert_equal jesse.email, retval["owner_email"]
		assert_equal "location", retval["location"]
		assert_equal "title", retval["title"]
		assert_equal 4, retval["material_type"]
	end

	test "material delete" do
		clear(User, Material)

		jesse = init_jesse

		retval = Material.check_and_create_new(jesse.email, 4, "location", "title")
		material_id = retval["material_id"]

		material_inst = Material.find_by_id(material_id)
		assert_equal Material, material_inst.class

		retval = material_inst.delete("wrong email")
		assert_equal ErrorEnum::UNAUTHORIZED, retval

		retval = material_inst.delete(jesse.email)
		assert_equal retval, true
		retval = Material.get_object(jesse.email, material_id)
		assert_equal ErrorEnum::MATERIAL_NOT_EXIST, retval
	end

	test "material title update" do
		clear(User, Material)

		jesse = init_jesse

		retval = Material.check_and_create_new(jesse.email, 4, "location", "title")
		material_id = retval["material_id"]

		material_inst = Material.find_by_id(material_id)
		assert_equal Material, material_inst.class

		retval = material_inst.update_title("wrong email", "new_title")
		assert_equal ErrorEnum::UNAUTHORIZED, retval

		retval = material_inst.update_title(jesse.email, "new_title")
		assert_equal "new_title", retval["title"]
		retval = Material.get_object(jesse.email, material_id)
		assert_equal "new_title", retval["title"]
	end
end
