require 'spec_helper'

describe "sessions" do

	before(:each) do
		clear(:AgentTask)
		clear(:Survey)
		@survey = FactoryGirl.create(:survey)
		@another_survey = FactoryGirl.create(:survey)
		@agent_task = FactoryGirl.create(:agent_task, :survey => @survey)
	end

	it "sign in" do
		post "/agent/sessions",
			agent_task: {email: @agent_task.email,
				password: Encryption.decrypt_password(@agent_task.password)},
			survey_id: @survey._id.to_s
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		expect(retval["auth_key"]).to eq AgentTask.first.auth_key

		post "/agent/sessions",
			agent_task: {email: @agent_task.email,
				password: Encryption.decrypt_password(@agent_task.password)},
			survey_id: @another_survey._id.to_s
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		expect(retval["error_code"]).to eq ErrorEnum::AGENT_TASK_NOT_EXIST
	end

	it "find agent task by auth key" do
		post "/agent/sessions",
			agent_task: {email: @agent_task.email,
				password: Encryption.decrypt_password(@agent_task.password)},
			survey_id: @survey._id.to_s

		get "/agent/sessions/login_with_auth_key",
			auth_key: AgentTask.all.first.auth_key
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		expect(retval["_id"]).to eq AgentTask.all.first._id.to_s
	end

	it "reset password" do
		post "/agent/sessions",
			agent_task: {email: @agent_task.email,
				password: Encryption.decrypt_password(@agent_task.password)},
			survey_id: @survey._id.to_s

		put "/agent/sessions/reset_password",
			auth_key: AgentTask.all.first.auth_key,
			old_password: Encryption.decrypt_password(AgentTask.all.first.password),
			new_password: "121212"
		response.status.should be 200
		retval = JSON.parse(response.body)["value"]
		expect(retval).to be true
		expect(Encryption.decrypt_password(AgentTask.all.first.password)).to eq "121212"
	end
end
