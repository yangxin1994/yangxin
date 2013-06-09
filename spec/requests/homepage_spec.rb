require 'spec_helper'

describe "home page" do
  it "Home page should show " do
  	post "http://127.0.0.1/admin/advertisements"
  	response.status.should be(200)
   true.should be_true
  end
end