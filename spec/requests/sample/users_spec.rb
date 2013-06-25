require 'spec_helper'

describe "users api" do

  before(:each) do
    10.times {FactoryGirl.create(:sample)}
  end

  it "return top rank users" do
    get "/sample/users/get_top_ranks"
      response.status.should be(200)
      retval = JSON.parse(response.body)["success"]
      expect(retval).to eq(true)
      ret    = JSON.parse(response.body)["value"]
      ret.length.should be 5
  end

end
