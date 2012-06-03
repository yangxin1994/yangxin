require 'test_helper'

class GroupTest < ActiveSupport::TestCase
	test "group creation" do
		clear(User, Group)

		jesse = init_jesse

		sub_groups = []
		retval = Group.check_and_create_new(jesse.email, "name_1", "description_1", [], [])
		sub_groups << retval["group_id"]
		retval = Group.check_and_create_new(jesse.email, "name_2", "description_2", [], [])
		sub_groups << retval["group_id"]
		retval = Group.check_and_create_new(jesse.email, "name_3", "description_3", [], [])
		sub_groups << retval["group_id"]
		retval = Group.check_and_create_new(jesse.email, "name_4", "description_4", [], [])
		sub_groups << retval["group_id"]

		members = generate_group_members

		retval = Group.check_and_create_new("wrong email", "new group", "new group description", members, sub_groups)
		assert_equal ErrorEnum::EMAIL_NOT_EXIST, retval

		retval = Group.check_and_create_new(jesse.email, "new group", "new group description", Marshal.load(Marshal.dump(members)) << {}, sub_groups)
		assert_equal ErrorEnum::ILLEGAL_EMAIL, retval

		retval = Group.check_and_create_new(jesse.email, "new group", "new group description", members, Marshal.load(Marshal.dump(sub_groups)) << "wrong group id")
		assert_equal ErrorEnum::GROUP_NOT_EXIST, retval

		retval = Group.check_and_create_new(jesse.email, "new group", "new group description", members, sub_groups)
		assert_equal "new group", retval["name"]
		assert_equal "new group description", retval["description"]
		assert_equal sub_groups, retval["sub_groups"]
	end

	test "group update" do
		clear(User, Group)

		jesse = init_jesse

		sub_groups = []
		retval = Group.check_and_create_new(jesse.email, "name_1", "description_1", [], [])
		sub_groups << retval["group_id"]
		retval = Group.check_and_create_new(jesse.email, "name_2", "description_2", [], [])
		sub_groups << retval["group_id"]
		retval = Group.check_and_create_new(jesse.email, "name_3", "description_3", [], [])
		sub_groups << retval["group_id"]
		retval = Group.check_and_create_new(jesse.email, "name_4", "description_4", [], [])
		sub_groups << retval["group_id"]

		members = generate_group_members
		retval = Group.check_and_create_new(jesse.email, "new group", "new group description", members, sub_groups)

		updated_group_obj = retval
		updated_group_obj["name"] = "updated group"
		updated_group_obj["description"] = "updated group description"
		updated_group_obj["members"] << {"email" => "new@member.com"}
		updated_group_obj["sub_groups"].delete_at(-1)

		group_inst = Group.find_by_id(retval["group_id"])
		assert_equal Group, group_inst.class
		
		retval = group_inst.update_group("wrong email", updated_group_obj)
		assert_equal ErrorEnum::UNAUTHORIZED, retval
	
		retval = group_inst.update_group(jesse.email, updated_group_obj)
		assert_equal "updated group", retval["name"]
		assert_equal "updated group description", retval["description"]
		assert_equal "new@member.com", retval["members"][-1]["email"]
		assert !retval["sub_groups"].include?(sub_groups[-1])
		retval = group_inst.show(jesse.email)
		assert_equal "updated group", retval["name"]
		assert_equal "updated group description", retval["description"]
		assert_equal "new@member.com", retval["members"][-1]["email"]
		assert !retval["sub_groups"].include?(sub_groups[-1])
	end

	test "group show" do
		clear(User, Group)

		jesse = init_jesse

		sub_groups = []
		retval = Group.check_and_create_new(jesse.email, "name_1", "description_1", [], [])
		sub_groups << retval["group_id"]
		retval = Group.check_and_create_new(jesse.email, "name_2", "description_2", [], [])
		sub_groups << retval["group_id"]
		retval = Group.check_and_create_new(jesse.email, "name_3", "description_3", [], [])
		sub_groups << retval["group_id"]
		retval = Group.check_and_create_new(jesse.email, "name_4", "description_4", [], [])
		sub_groups << retval["group_id"]

		members = generate_group_members
		retval = Group.check_and_create_new(jesse.email, "new group", "new group description", members, sub_groups)

		group_inst = Group.find_by_id(retval["group_id"])
		assert_equal Group, group_inst.class

		retval = group_inst.show("wrong email")
		assert_equal ErrorEnum::UNAUTHORIZED, retval

		retval = group_inst.show(jesse.email)
		assert_equal "new group", retval["name"]
		assert_equal "new group description", retval["description"]
		assert_equal members[0]["email"], retval["members"][0]["email"]
		assert_equal members[0]["mobile"], retval["members"][0]["mobile"]
		assert_equal true, retval["members"][0]["is_exclusive"]
		assert_equal sub_groups, retval["sub_groups"]
	end

	test "group delete" do
		clear(User, Group)

		jesse = init_jesse

		members = generate_group_members
		retval = Group.check_and_create_new(jesse.email, "new group", "new group description", [], [])
		group_id = retval["group_id"]
		parent_group = Group.check_and_create_new(jesse.email, "new group", "new group description", [], [retval["group_id"]])

		group_inst = Group.find_by_id(group_id)
		assert_equal Group, group_inst.class

		retval = group_inst.delete("wrong email")
		assert_equal ErrorEnum::UNAUTHORIZED, retval

		retval = group_inst.delete(jesse.email)
		assert_equal retval, true
		retval = Group.find_by_id(group_id)
		assert_nil retval
		parent_group_inst = Group.find_by_id(parent_group["group_id"])
		parent_group_obj = parent_group_inst.show(jesse.email)
		assert !parent_group_obj["sub_groups"].include?(group_id)
	end
end
