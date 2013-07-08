require 'spec_helper'

describe "public notices api" do

  before(:each) do
    FactoryGirl.create_list(:public_notice, 20)
  end

  it "return newest public notices" do
    get "/sample/public_notices/get_newest",
      page: 1,
	    per_page: 4
      response.status.should be(200)
      retval = JSON.parse(response.body)["success"]
      expect(retval).to eq(true)
      ret    = JSON.parse(response.body)["value"]["data"]
      ret.length.should be 4
  end

  after(:each) do
    clear(:PublicNotice)
  end

end
