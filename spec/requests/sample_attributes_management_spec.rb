require 'spec_helper'

describe "sample attributes management" do

	before(:each) do
		clear_sample_attribute
		@auth_key = admin_signin
	end

	before(:each, :populate_sample_attributes => true) do
		populate_sample_attributes
	end

	def clear_sample_attribute
		clear(:SampleAttribute)
		clear(:User)
	end


	def populate_sample_attributes
		@gender = FactoryGirl.create(:gender)
		@birth = FactoryGirl.create(:birth)
		@interests = FactoryGirl.create(:interests)
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
			JSON.dump(sample_attribute: {name: "interests", type: 7, element_type: 1, enum_array: ["basketball", "football", "swimming", "pingpang", "badminton"]},
				auth_key: @auth_key),
			"CONTENT_TYPE" => "application/json"
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
			JSON.dump(sample_attribute: {name: "gender", type: 8},
				auth_key: @auth_key),
			"CONTENT_TYPE" => "application/json"
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]["error_code"]
		expect(retval).to eq(ErrorEnum::WRONG_SAMPLE_ATTRIBUTE_TYPE)

		# create enum type sample attribute
		post "/admin/sample_attributes",
			JSON.dump(sample_attribute: {name: "gender", type: 1, enum_array: ["mail", "female"]},
				auth_key: @auth_key),
			"CONTENT_TYPE" => "application/json"
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		retval.should be(true)

		# create date type sample attribute with wrong date type
		post "/admin/sample_attributes",
			JSON.dump(sample_attribute: {name: "birth", type: 3, date_type: 5},
				auth_key: @auth_key),
			"CONTENT_TYPE" => "application/json"
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]["error_code"]
		expect(retval).to eq(ErrorEnum::WRONG_DATE_TYPE)

		# create date type sample attribute
		post "/admin/sample_attributes",
			JSON.dump(sample_attribute: {name: "birth", type: 3, date_type: 2},
				auth_key: @auth_key),
			"CONTENT_TYPE" => "application/json"
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		retval.should be(true)

		# create array type sample attribute
		post "/admin/sample_attributes",
			JSON.dump(sample_attribute: {name: "interests", type: 7, element_type: 1, enum_array: ["basketball", "football", "swimming", "pingpang"]},
				auth_key: @auth_key),
			"CONTENT_TYPE" => "application/json"
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
		expect(retval["data"][1]["name"]).to eq("gender")
		expect(retval["data"][1]["type"]).to eq(1)

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

	it "bind a question to a sample attribute", :populate_sample_attributes => true do
		clear(:Question)
		@choice_question = FactoryGirl.create(:choice_question)
		@text_blank_question = FactoryGirl.create(:text_blank_question)
		@number_blank_question = FactoryGirl.create(:number_blank_question)

		@name = FactoryGirl.create(:name)
		@weight = FactoryGirl.create(:weight)
		@salary = FactoryGirl.create(:salary)
		@graduated_at = FactoryGirl.create(:graduated_at)
		@address = FactoryGirl.create(:address)

		put "/admin/sample_attributes/#{@name._id}/bind_question.json",
			JSON.dump(question_id: @text_blank_question._id.to_s,
				relation: {},
				auth_key: @auth_key),
			"CONTENT_TYPE" => "application/json"
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		retval.should be true

		gender_relation = {}
		@choice_question.issue["items"].each_with_index do |item, index|
			gender_relation[item["id"].to_s] = index % 2
		end

		put "/admin/sample_attributes/#{@gender._id}/bind_question",
			JSON.dump(question_id: @choice_question._id.to_s,
				relation: gender_relation,
				auth_key: @auth_key),
			"CONTENT_TYPE" => "application/json"
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		retval.should be true

		get "/admin/questions/#{@choice_question._id}",
			auth_key: @auth_key
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		expect(retval["sample_attribute_relation"]).to eq(gender_relation)
	end
end
