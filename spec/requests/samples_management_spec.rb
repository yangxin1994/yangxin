require 'spec_helper'

describe "samples management" do

	before(:each) do
		clear_sample
		@auth_key = admin_signin
	end

	before(:each, :populate_sample_attributes => true) do
		populate_sample_attributes
	end

	before(:each, :populate_samples => true) do
		populate_samples
	end

	def clear_sample
		clear(:User)
	end

	def populate_sample_attributes
		@gender = FactoryGirl.create(:gender)
		@birth = FactoryGirl.create(:birth)
		@interests = FactoryGirl.create(:interests)
	end

	def populate_samples
		5.times { FactoryGirl.create(:sample) }
	end

	it "search samples", :populate_samples => true do
		get "/admin/samples",
			page: 1,
			per_page: 10,
			auth_key: @auth_key
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		retval["data"].length.should be 5
	end
end
