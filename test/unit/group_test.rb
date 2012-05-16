require 'test_helper'

class GroupTest < ActiveSupport::TestCase
	test "group creation" do
		clear(User, Group)

		jesse = init_jesse

		members = generate_group_members
		retval = Group.check_and_create_new("wrong email", "new group", "new group description", members)
		assert_equal ErrorEnum::EMAIL_NOT_EXIST, retval

		retval = Group.check_and_create_new(jesse.email, "new group", "new group description", members)
		assert_equal "new group", retval["name"]
		assert_equal "new group description", retval["description"]
		assert_equal members[0], retval["members"][0]
	end

	test "group update" do
		clear(User, Group)

		jesse = init_jesse

		members = generate_group_members
		retval = Group.check_and_create_new(jesse.email, "new group", "new group description", members)

		updated_group_obj = retval
		updated_group_obj["name"] = "updated group"
		updated_group_obj["description"] = "updated group description"
		updated_group_obj["members"] << "new@member.com"
		
		retval = Group.update("wrong email", updated_group_obj["group_id"], updated_group_obj)
		assert_equal ErrorEnum::UNAUTHORIZED, retval
	
		retval = Group.update(jesse.email, "wrong id", updated_group_obj)
		assert_equal ErrorEnum::GROUP_NOT_EXIST, retval
	
		retval = Group.update(jesse.email, updated_group_obj["group_id"], updated_group_obj)
		assert_equal "updated group", retval["name"]
		assert_equal "updated group description", retval["description"]
		assert_equal "new@member.com", retval["members"][-1]
	end

	test "group show" do
		clear(User, Group)

		jesse = init_jesse

		members = generate_group_members
		retval = Group.check_and_create_new(jesse.email, "new group", "new group description", members)
		group_id = retval["group_id"]

		retval = Group.show(jesse.email, "wrong group id")
		assert_equal ErrorEnum::GROUP_NOT_EXIST, retval

		retval = Group.show("wrong email", group_id)
		assert_equal ErrorEnum::UNAUTHORIZED, retval

		retval = Group.show(jesse.email, group_id)
		assert_equal "new group", retval["name"]
		assert_equal "new group description", retval["description"]
		assert_equal "a@a.com", retval["members"][0]
	end

	test "group delete" do
		clear(User, Group)

		jesse = init_jesse

		members = generate_group_members
		retval = Group.check_and_create_new(jesse.email, "new group", "new group description", members)
		group_id = retval["group_id"]

		retval = Group.delete(jesse.email, "wrong group id")
		assert_equal ErrorEnum::GROUP_NOT_EXIST, retval

		retval = Group.delete("wrong email", group_id)
		assert_equal ErrorEnum::UNAUTHORIZED, retval

		retval = Group.delete(jesse.email, group_id)
		assert_equal retval, true
		retval = Group.show(jesse.email, group_id)
		assert_equal ErrorEnum::GROUP_NOT_EXIST, retval
	end
end
