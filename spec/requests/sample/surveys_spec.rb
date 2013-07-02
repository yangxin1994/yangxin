require 'spec_helper'

describe "surveys api" do

  before(:each) do
    @surveys = FactoryGirl.create_list(:survey, 10)
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
      count = 0
      Survey.all.each {|s|count += 1 if s.status == 2}
      expect(retval).to eq(true)
      ret['data'].length.should be count
  end

  after(:each) do
    clear(:Survey)
  end

end
