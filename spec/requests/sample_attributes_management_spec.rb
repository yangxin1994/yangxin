require 'spec_helper'

describe "sample attribute management" do

	before(:each) do
		clear_sample_attribute
		@auth_key = admin_signin
	end

	before(:each, :populate_sample_attributes => true) do
		populate_sample_attributes
	end

	def clear_sample_attribute
		clear(:SampleAttribute)
	end

	def populate_sample_attributes
		FactoryGirl.create(:gender)
		FactoryGirl.create(:birth)
		FactoryGirl.create(:interests)
	end

	it "update a sample attribute", :populate_sample_attributes => true do
		get "/admin/sample_attributes",
			page: 1,
			per_page: 2,
			name: "inte",
			auth_key: @auth_key
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		interest_attribute = retval["data"][0]
		interest_attribute_id = interest_attribute["_id"]

		put "/admin/sample_attributes/#{interest_attribute_id}",
			sample_attribute: {name: "interests",
				type: 7,
				element_type: 1,
				enum_array: ["basketball", "football", "swimming", "pingpang", "badminton"]},
			auth_key: @auth_key
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		retval.should be(true)

		get "/admin/sample_attributes",
			page: 1,
			per_page: 2,
			name: "inte",
			auth_key: @auth_key
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		expect(retval["data"][0]["type"]).to eq(7)
		expect(retval["data"][0]["element_type"]).to eq(1)
		expect(retval["data"][0]["enum_array"]).to eq(["basketball", "football", "swimming", "pingpang", "badminton"])
	end

	it "destroy a sample attribute", :populate_sample_attributes => true do
		get "/admin/sample_attributes",
			page: 1,
			per_page: 2,
			name: "inte",
			auth_key: @auth_key
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		interest_attribute = retval["data"][0]
		interest_attribute_id = interest_attribute["_id"]

		# destroy a sample attribute
		delete "/admin/sample_attributes/#{interest_attribute_id}",
			auth_key: @auth_key
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		retval.should be(true)

		get "/admin/sample_attributes",
			page: 1,
			per_page: 2,
			name: "inte",
			auth_key: @auth_key
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		expect(retval["data"].length).to eq(0)
	end

	it "create a sample attribute" do
		# create with wrong sample attribute data type
		post "/admin/sample_attributes",
			sample_attribute: {name: "gender",
				type: 8},
			auth_key: @auth_key
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]["error_code"]
		expect(retval).to eq(ErrorEnum::WRONG_SAMPLE_ATTRIBUTE_TYPE)

		# create enum type sample attribute
		post "/admin/sample_attributes",
			sample_attribute: {name: "gender",
				type: 1,
				enum_array: ["mail", "female"]},
			auth_key: @auth_key
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		retval.should be(true)

		# create date type sample attribute with wrong date type
		post "/admin/sample_attributes",
			sample_attribute: {name: "birth",
				type: 3,
				date_type: 5},
			auth_key: @auth_key
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]["error_code"]
		expect(retval).to eq(ErrorEnum::WRONG_DATE_TYPE)

		# create date type sample attribute
		post "/admin/sample_attributes",
			sample_attribute: {name: "birth",
				type: 3,
				date_type: 2},
			auth_key: @auth_key
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		retval.should be(true)

		# create array type sample attribute
		post "/admin/sample_attributes",
			sample_attribute: {name: "interests",
				type: 7,
				element_type: 1,
				enum_array: ["basketball", "football", "swimming", "pingpang"]},
			auth_key: @auth_key
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		retval.should be(true)

		# list all sample attributes
		get "/admin/sample_attributes",
			page: 1,
			per_page: 2,
			auth_key: @auth_key
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		expect(retval["data"].length).to eq(2)
		expect(retval["data"][0]["name"]).to eq("gender")
		expect(retval["data"][0]["type"]).to eq(1)

		get "/admin/sample_attributes",
			page: 1,
			per_page: 2,
			name: "inte",
			auth_key: @auth_key
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		expect(retval["data"][0]["type"]).to eq(7)
		expect(retval["data"][0]["element_type"]).to eq(1)
		expect(retval["data"][0]["enum_array"]).to eq(["basketball", "football", "swimming", "pingpang"])
	end
end
