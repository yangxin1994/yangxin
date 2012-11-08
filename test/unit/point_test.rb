require 'test_helper'

class PointTest < ActiveSupport::TestCase
	setup do
		clear(User, RewardLog)
		@ponit_log = FactoryGirl.create(:increase_point) 
		@admin_foo = User.first
		@user_bar = User.last
	end

	test "increase point" do
		p = RewardLog.create(:operated_point => -200,
											:cause => 0,
											:operated_admin => @admin_foo,
											:user => @user_bar )
		assert @user_bar.point == 1300
	end

	test "revoke a operation" do
		RewardLog.revoke_operation(@ponit_log.id, @admin_foo.id)
		@user_bar.reload
		assert @user_bar.point == 1000
	end
end
