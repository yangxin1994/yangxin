require 'spec_helper'

describe "surveys api" do

  before(:each) do
    10.times {@survey = FactoryGirl.create(:survey)}
  end

  it "return hot survey" do
  	s = FactoryGirl.create(:survey)
  	s.update_attributes(:status => 2)
    get "/sample/surveys/get_hot_spot_survey",
      page: 1,
	  per_page: 4
      response.status.should be(200)
      retval = JSON.parse(response.body)["success"]
      expect(retval).to eq(true)
      #retval.length.should be 1
  end


  it "return recommend surveys" do
    get "/sample/surveys/get_recommends",
      page: 1,
	  per_page: 4
      response.status.should be(200)
      retval = JSON.parse(response.body)["success"]
      ret    = JSON.parse(response.body)["value"]
      expect(retval).to eq(true)
      ret['data'].length.should be 4
  end

end
