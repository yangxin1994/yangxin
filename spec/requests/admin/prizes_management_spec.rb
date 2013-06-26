require 'spec_helper'

describe "prizes management" do

	before(:each) do
		clear(:User)
		clear(:Prize)
		@auth_key = admin_signin
	end

	before(:each, :populate_prizes => true) do
		populate_prizes
	end

	def populate_prizes
		6.times do
			prize = FactoryGirl.create(:prize)
			material = FactoryGirl.create(:material, :prize => prize)
		end
	end

	it "search prizes", :populate_prizes => true do
		get "/admin/prizes",
			page: 1,
			per_page: 10,
			auth_key: @auth_key
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		retval["data"].length.should be 6

		get "/admin/prizes",
			page: 1,
			per_page: 10,
			title: "the",
			status: 1,
			type: 3,
			auth_key: @auth_key
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		retval["data"].length.should be 4
	end

	it "create prize" do
		material = FactoryGirl.create(:material)
		post "admin/prizes",
			JSON.dump(prize: {title: "new prize",
					description: "description of the new prize",
					type: 1,
					material_id: material._id.to_s},
				auth_key: @auth_key),
			"CONTENT_TYPE" => "application/json"
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		expect(retval["photo_url"]).to eq "/image/1.jpg"
		Prize.all.length.should be 1
		expect(Prize.all.first.title).to eq "new prize"
	end

	it "update prize", :populate_prizes => true do
		material = FactoryGirl.create(:material)
		prize = Prize.first
		put "admin/prizes/#{prize._id.to_s}",
			JSON.dump(prize: {title: "updated prize",
					description: "description of the updated prize",
					type: 1,
					material_id: material._id.to_s},
				auth_key: @auth_key),
			"CONTENT_TYPE" => "application/json"
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		retval.should be(true)
		updated_prize = Prize.find_by_id(prize._id.to_s)
		expect(updated_prize.title).to eq "updated prize"
	end

	it "delete prize", :populate_prizes => true do
		delete "/admin/prizes/#{Prize.all.first._id}",
			auth_key: @auth_key
		response.status.should be(200)
		JSON.parse(response.body)["value"].should be true
		Prize.normal.all.length.should be 5
	end

end
