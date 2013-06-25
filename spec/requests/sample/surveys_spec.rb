require 'spec_helper'

describe "surveys api" do
  it "return hot survey" do
    get "/sample/surveys/get_hot_spot_survey"
      response.status.should be(200)
      retval = JSON.parse(response.body)["value"]
      retval["data"].length.should be 1
  end
end
