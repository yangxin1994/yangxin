require 'spec_helper'

describe "answers management" do

  before(:all) do
    clear(:User)
    @auth_key = user_signin(:answer_auditor)
    @current_user = User.all.first
  end

  describe "visit /index" do

    before(:all) do
      @survey = FactoryGirl.create(:survey)
      @agent_task = FactoryGirl.create(:agent_task)
      @answers = FactoryGirl.create_list(:answer, 10) { |a| @survey.answers << a}
      FactoryGirl.create_list(:answer, 10)
    end

    it "when user has no survey to audit should return SURVEY_NOT_EXIST" do
      get "/answer_auditor/answers",
        survey_id: @survey.id.to_s,
        auth_key: @auth_key
      response.status.should be(200)
      retval = JSON.parse(response.body)["value"]["error_code"]
      expect(retval).to eq(ErrorEnum::SURVEY_NOT_EXIST)
    end

    it "should return 10 messages" do
      @current_user.answer_auditor_allocated_surveys << @survey
      get "/answer_auditor/answers",
        survey_id: @survey.id.to_s,
        auth_key: @auth_key
      response.status.should be(200)
      retval = JSON.parse(response.body)["value"]["data"]
      expect(retval.length).to eq(10)
    end

    it "search status should return 0 messages" do
      @current_user.answer_auditor_allocated_surveys << @survey
      get "/answer_auditor/answers",
        survey_id: @survey.id.to_s,
        status: 0,
        auth_key: @auth_key
      response.status.should be(200)
      retval = JSON.parse(response.body)["value"]["data"]
      expect(retval.length).to eq(0)
    end

    it "search agent_task should return 0 messages" do
      @current_user.answer_auditor_allocated_surveys << @survey
      get "/answer_auditor/answers",
        survey_id: @survey.id.to_s,
        agent_task_id: 0,
        auth_key: @auth_key
      response.status.should be(200)
      retval = JSON.parse(response.body)["value"]["error_code"]
      expect(retval).to eq(ErrorEnum::AGENT_TASK_NOT_EXIST)
    end

    it "search agent_task should return 5 messages" do
      @current_user.answer_auditor_allocated_surveys << @survey
      @survey.agent_tasks << @agent_task
      @answers[0..4].each { |a| @agent_task.answers << a}
      get "/answer_auditor/answers",
        survey_id: @survey.id.to_s,
        agent_task_id: @agent_task.id.to_s,
        auth_key: @auth_key
      response.status.should be(200)
      retval = JSON.parse(response.body)["value"]["data"]
      expect(retval.length).to eq(5)
    end

    after(:all) do
      clear(:AgentTask)
      clear(:Survey)
      clear(:Answer)
    end
  end

  describe "visit /show" do
    before(:all) do
      @answer = FactoryGirl.create(:answer)
    end

    it "should return a answer" do
      get "/answer_auditor/answers/#{@answer.id}",
        auth_key: @auth_key
      response.status.should be(200)
      retval = JSON.parse(response.body)["value"]
      ## TODO to be completed
      expect(retval).to eq(retval)
    end

    after(:all) do
      clear(:AgentTask)
      clear(:Survey)
      clear(:Answer)
    end
  end

  describe "visit /reward" do
    before(:each) do
      @answer = FactoryGirl.create(:answer)
    end

    it "answer status should be 4 after review" do
      put "/answer_auditor/answers/#{@answer.id}/review",
        review_result: true,
        message_content: "good",
        auth_key: @auth_key
      retval = JSON.parse(response.body)["value"]
      expect(retval).to eq(true)
    end

    after(:each) do
      clear(:Answer)
    end
  end

end
