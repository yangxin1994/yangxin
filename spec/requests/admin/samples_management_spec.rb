require 'spec_helper'

describe "samples management" do

	before(:each) do
		clear(:User)
		clear(:SampleAttribute)
		clear(:Log)
		@auth_key = admin_signin
	end

	before(:each, :populate_samples => true) do
		populate_samples
	end

	def populate_samples
		6.times { FactoryGirl.create(:sample) }
	end

	it "search samples", :populate_samples => true do
		get "/admin/samples",
			page: 1,
			per_page: 10,
			auth_key: @auth_key
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		retval["data"].length.should be 3

		get "/admin/samples",
			page: 1,
			per_page: 10,
			is_block: true,
			auth_key: @auth_key
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		retval["data"].length.should be 6
	end

	it "show a sample" do
		FactoryGirl.create(:gender)
		FactoryGirl.create(:birth)
		s = FactoryGirl.create(:sample)
		s.write_attribute("gender", 0)
		birth_time = Time.now.to_i
		s.write_attribute("birth", birth_time)
		s.save

		get "/admin/samples/#{s._id}",
			auth_key: @auth_key
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		expect(retval["attributes"]["birth"]["value"]).to eq(birth_time)
		expect(retval["attributes"]["gender"]).to eq("male")
	end

	it "count samples number", :populate_samples => true do
		sleep(1)
		get "/admin/samples/count",
			period: "year",
			time_length: 3,
			auth_key: @auth_key
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		retval["normal_sample_number"].should be 3
		retval["block_sample_number"].should be 3
		expect(retval["new_sample_number"]).to eq [0, 0, 6]
	end

	it "block sample" do
		s = FactoryGirl.create(:sample)
		post "/admin/samples/#{s._id}/block",
			JSON.dump(block: true,
				auth_key: @auth_key),
			"CONTENT_TYPE" => "application/json"
		response.status.should be(200)
		JSON.parse(response.body)["value"].should be true

		get "/admin/samples/#{s._id}",
			auth_key: @auth_key
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		retval["is_block"].should be true

		s = FactoryGirl.create(:sample)
		post "/admin/samples/#{s._id}/block",
			JSON.dump(block: false,
				auth_key: @auth_key),
			"CONTENT_TYPE" => "application/json"
		response.status.should be(200)
		JSON.parse(response.body)["value"].should be true

		get "/admin/samples/#{s._id}",
			auth_key: @auth_key
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		retval["is_block"].should be false
	end

	it "show sample logs" do
		s1 = FactoryGirl.create(:sample)
		s2 = FactoryGirl.create(:sample)

		FactoryGirl.create(:lottery_log, :user => s1)
		2.times { FactoryGirl.create(:point_log, :user => s1) }
		3.times { FactoryGirl.create(:redeem_log, :user => s1) }

		get "/admin/samples/#{s1._id}/lottery_log",
			page: 1,
			per_page: 5,
			auth_key: @auth_key
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		retval["data"].length.should be 1

		get "/admin/samples/#{s1._id}/point_log",
			page: 1,
			per_page: 5,
			auth_key: @auth_key
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		retval["data"].length.should be 2

		get "/admin/samples/#{s1._id}/redeem_log",
			page: 1,
			per_page: 5,
			auth_key: @auth_key
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		retval["data"].length.should be 3

		get "/admin/samples/#{s2._id}/redeem_log",
			page: 1,
			per_page: 5,
			auth_key: @auth_key
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		retval["data"].length.should be 0
	end

	it "count active samples" do
		User.sample.destroy_all
		s1 = FactoryGirl.create(:sample)
		s2 = FactoryGirl.create(:sample)

		FactoryGirl.create(:lottery_log, :user => s1)
		2.times { FactoryGirl.create(:point_log, :user => s1) }
		3.times { FactoryGirl.create(:redeem_log, :user => s1) }
		sleep(1)

		get "/admin/samples/active_count",
			period: "day",
			time_length: 5,
			auth_key: @auth_key
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
	end
end
