require 'spec_helper'

describe "logs api" do

  before(:each) do
    10.times {FactoryGirl.create(:lottery_log)}
    10.times {FactoryGirl.create(:redeem_log)}
    10.times {FactoryGirl.create(:point_log)}
  end

  it "return fresh_news" do
    get "/sample/logs/fresh_news"
      response.status.should be(200)
      retval = JSON.parse(response.body)["success"]
      expect(retval).to eq(true)
      ret    = JSON.parse(response.body)["value"]
      ret.length.should be 5
  end

end
