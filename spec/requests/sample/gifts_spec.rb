require 'spec_helper'

describe "gifts api" do

  before(:each) do
    50.times {FactoryGirl.create(:gift)}
  end

  it "return hotest gitts" do
    get "/sample/gifts/hotest",
      page: 1,
	    per_page: 4
      response.status.should be(200)
      retval = JSON.parse(response.body)["success"]
      expect(retval).to eq(true)
  end


  it "return specify gift" do
    gift = FactoryGirl.create(:gift) 
    get "/sample/gifts/#{gift.id}"
      response.status.should be(200)
      retval = JSON.parse(response.body)["success"]
      ret    = JSON.parse(response.body)["value"]
      expect(retval).to eq(true)
  end

end
