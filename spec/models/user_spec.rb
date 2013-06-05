require "spec_helper"

describe User do
	it "orders by last name" do
    user = Factory(:user)
    user.username.should == 'test'
  end
end