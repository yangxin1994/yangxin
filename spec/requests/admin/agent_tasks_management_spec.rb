require 'spec_helper'

describe "agent tasks management" do

	before(:each) do
		clear(:User)
		clear(:AgentTask)
		@auth_key = admin_signin
	end

	before(:each, :populate_agent_tasks => true) do
		populate_agent_tasks
	end

	def populate_agent_tasks
	end

	it "search agent_tasks", :populate_agent_tasks => true do
		get "/admin/agent_tasks",
			page: 1,
			per_page: 10,
			auth_key: @auth_key
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		retval["data"].length.should be 6

		get "/admin/agent_tasks",
			page: 1,
			per_page: 10,
			title: "the",
			status: 7,
			auth_key: @auth_key
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		retval["data"].length.should be 3
	end

	it "create agent task" do
		survey = FactoryGirl.create(:survey)
		post "admin/agent_tasks",
			JSON.dump(agent_task: {survey_id: survey._id.to_s,
					description: "description of the new agent task"},
				auth_key: @auth_key),
			"CONTENT_TYPE" => "application/json"
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		puts "11111111111111"
		puts retval.inspect
		puts "11111111111111"
		AgentTask.all.length.should be 1
		expect(AgentTask.all.first.description).to eq "description of the new agent task"
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
