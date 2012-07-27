require 'test_helper'

class PointTest < ActiveSupport::TestCase
	setup do
		clear(User, PointLog)
		@ponit_log = FactoryGirl.create(:increase_point) 
		@admin_bar = User.first
		@user_foo = User.last
	end

	test "increase point" do
		p = PointLog.create(:operated_point => -200,
											:cause => 0,
											:operated_admin => @admin_bar,
											:user => @user_foo )
		assert @user_foo.point == 1300
	end

	test "revoke a operation" do
		PointLog.revoke_operation(@ponit_log.id, @admin_bar.id)
		@user_foo.reload
		assert @user_foo.point == 1000
	end
end
