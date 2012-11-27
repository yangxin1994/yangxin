require 'test_helper'

class RewardLogTest < ActiveSupport::TestCase
	setup do
		clear(User, RewardLog)
		@ponit_log = FactoryGirl.create(:increase_point) 
		@admin_foo = FactoryGirl.create(:admin_foo)
		@user_bar = FactoryGirl.create(:user_bar)
	end

end
