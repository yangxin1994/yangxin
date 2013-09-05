require 'spec_helper'

describe "answer auditors management" do

  before(:each) do
    @auth_key = admin_signin
  end

  describe "visit /index" do

    before(:all) do
      @answer_auditors = FactoryGirl.create_list(:answer_auditor, 10)
      @sample = FactoryGirl.create_list(:sample, 10)
    end

    it "should return right messages" do
      get "/admin/answer_auditors",
        auth_key: @auth_key
      response.status.should be(200)
      retval = JSON.parse(response.body)["value"]
      expect(retval.length).to eq(10)
    end
  end

end
