require 'test_helper'

class RewardLogTest < ActiveSupport::TestCase
	setup do
		clear(User, RewardLog)
		@ponit_log = FactoryGirl.create(:increase_point) 
		@admin_foo = FactoryGirl.create(:admin_foo)
		@user_bar = FactoryGirl.create(:user_bar)
	end

	test "increase point" do
		r = RewardLog.create(:point => -200,
											:type => 2,
											:cause => 0,
											:operator => @admin_foo,
											:user => @user_bar )
		assert @user_bar.point == 800
	end

	test "revoke a operation" do
		RewardLog.revoke_operation(@ponit_log.id, @admin_foo.id)
		@user_bar.reload
		assert @user_bar.point == 1000
	end
end
