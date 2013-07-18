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
		6.times do
			survey = FactoryGirl.create(:survey)
			FactoryGirl.create(:agent_task, :survey => survey)
		end
	end

	it "search agent_tasks", :focus => true, :populate_agent_tasks => true do
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
			status: 1,
			auth_key: @auth_key
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		retval["data"].length.should be 3
	end

	it "create agent task" do
		survey = FactoryGirl.create(:survey)
		post "admin/agent_tasks",
			JSON.dump(agent_task: {survey_id: survey._id.to_s,
					email: "test@test.com",
					password: "111111",
					count: 100,
					description: "description of the new agent task"},
				auth_key: @auth_key),
			"CONTENT_TYPE" => "application/json"
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		AgentTask.all.length.should be 1
		expect(AgentTask.all.first.description).to eq "description of the new agent task"
	end

	it "update agent task", :populate_agent_tasks => true do
		agent_task = AgentTask.first
		put "admin/agent_tasks/#{agent_task._id.to_s}",
			JSON.dump(agent_task: {email: "update@test.com",
					description: "description of the updated agent task",
					count: 200},
				auth_key: @auth_key),
			"CONTENT_TYPE" => "application/json"
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		retval.should be(true)
		updated_agent_task = AgentTask.find_by_id(agent_task._id.to_s)
		expect(updated_agent_task.email).to eq "update@test.com"
		expect(updated_agent_task.description).to eq "description of the updated agent task"
		expect(updated_agent_task.count).to eq 200
	end

	it "delete agent task", :populate_agent_tasks => true do
		delete "/admin/agent_tasks/#{AgentTask.all.first._id}",
			auth_key: @auth_key
		response.status.should be(200)
		JSON.parse(response.body)["value"].should be true
		AgentTask.normal.all.length.should be 5
	end

	it "reset password", :populate_agent_tasks => true do
		agent_task = AgentTask.normal.first
		put "admin/agent_tasks/#{agent_task._id.to_s}/reset_password",
			old_password: Encryption.decrypt_password(agent_task.password),
			new_password: "123456",
			auth_key: @auth_key
		response.status.should be(200)
		JSON.parse(response.body)["value"].should be true
		expect(Encryption.decrypt_password(AgentTask.find_by_id(agent_task._id).password)).to eq "123456"
	end
end
