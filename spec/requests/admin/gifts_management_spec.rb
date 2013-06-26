require 'spec_helper'

describe "gifts management" do

	before(:each) do
		clear(:User)
		clear(:Gift)
		@auth_key = admin_signin
	end

	before(:each, :populate_gifts => true) do
		populate_gifts
	end

	def populate_gifts
		6.times do
			gift = FactoryGirl.create(:gift)
			FactoryGirl.create(:material, :gift => gift)
		end
	end

	it "search gifts", :populate_gifts => true do
		get "/admin/gifts",
			page: 1,
			per_page: 10,
			auth_key: @auth_key
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		retval["data"].length.should be 6

		get "/admin/gifts",
			page: 1,
			per_page: 10,
			title: "the",
			status: 1,
			type: 7,
			auth_key: @auth_key
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		retval["data"].length.should be 3
	end

	it "create gift" do
		material = FactoryGirl.create(:material)
		post "admin/gifts",
			JSON.dump(gift: {title: "new gift",
					description: "description of the new gift",
					quantity: 1,
					type: 1,
					point: 100,
					material_id: material._id.to_s},
				auth_key: @auth_key),
			"CONTENT_TYPE" => "application/json"
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		expect(retval["photo_url"]).to eq "/image/1.jpg"
		Gift.all.length.should be 1
		expect(Gift.all.first.title).to eq "new gift"
	end

	it "update gift", :populate_gifts => true do
		material = FactoryGirl.create(:material)
		gift = Gift.first
		put "admin/gifts/#{gift._id.to_s}",
			JSON.dump(gift: {title: "updated gift",
					description: "description of the updated gift",
					quantity: 1,
					type: 1,
					point: 100,
					material_id: material._id.to_s},
				auth_key: @auth_key),
			"CONTENT_TYPE" => "application/json"
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		retval.should be(true)
		updated_gift = Gift.find_by_id(gift._id.to_s)
		expect(updated_gift.title).to eq "updated gift"
	end

	it "delete gift", :populate_gifts => true do
		delete "/admin/gifts/#{Gift.all.first._id}",
			auth_key: @auth_key
		response.status.should be(200)
		JSON.parse(response.body)["value"].should be true
		Gift.normal.all.length.should be 5
	end

end
