require 'spec_helper'

describe "public notices management" do

  before(:all) do
    clear(:PublicNotice)
    @auth_key = admin_signin
    @admin = FactoryGirl.create(:admin)
  end

  describe "visit /index" do

    before(:each) do
      @public_notices = FactoryGirl.create_list(:public_notice, 20)
      FactoryGirl.create_list(:public_notice_deleted, 10)
      @admin.id = @public_notices[0].user_id
      @public_notices.each { |p| @admin.public_notices << p}
    end

    it "should return valid notices" do
      get "admin/public_notices",
        page: 1,
        per_page: 30,
        auth_key: @auth_key
      response.status.should be(200)
      retval = JSON.parse(response.body)["value"]["data"]
      expect(retval.length).to eq(20)
    end

    it "search title should return all notices" do
      get "admin/public_notices",
        page: 1,
        per_page: 30,
        title: "86@gmail",
        auth_key: @auth_key
      response.status.should be(200)
      retval = JSON.parse(response.body)["value"]["data"]
      expect(retval.length).to eq(20)
    end

    after(:each) do
      clear(:PublicNotice)
    end
  end

  describe "visit /show" do
    before(:all) do
      @public_notice = FactoryGirl.create(:public_notice)
    end

    it "should return a public_notice" do
      get "admin/public_notices/#{@public_notice.id}",
        auth_key: @auth_key
      response.status.should be(200)
      retval = JSON.parse(response.body)["value"]
      expect(retval["_id"]).to eq(@public_notice.id.to_s)
      expect(retval["title"]).to eq(@public_notice.title)
      expect(retval["content"]).to eq(@public_notice.content)
      expect(retval["status"]).to eq(@public_notice.status)
    end

    it "should return PUBLIC_NOTICE_NOT_EXIST" do
      get "admin/public_notices/#{@public_notice.id.to_s.next}",
        auth_key: @auth_key
      response.status.should be(200)
      retval = JSON.parse(response.body)["value"]["error_code"]
      expect(retval).to eq(ErrorEnum::PUBLIC_NOTICE_NOT_EXIST)
    end

    after(:all) do
      clear(:PublicNotice)
    end
  end

  describe "visit /create" do
    before(:all) do
      @public_notice = FactoryGirl.build(:public_notice)
    end

    it "should return true" do
      public_notice = @public_notice.attributes
      public_notice.delete("_id")
      post "admin/public_notices",
        JSON.dump(
            public_notice: public_notice,
            auth_key: @auth_key),
            "CONTENT_TYPE" => "application/json"
      response.status.should be(200)
      retval = JSON.parse(response.body)["value"]
      expect(retval).to eq(true)
    end

    it "should return PUBLIC_NOTICE_NOT_EXIST" do
      public_notice = @public_notice.attributes
      public_notice.delete("_id")
      public_notice["status"] = 4
      post "admin/public_notices",
        JSON.dump(
            public_notice: public_notice,
            auth_key: @auth_key),
        "CONTENT_TYPE" => "application/json"
      response.status.should be(200)
      retval = JSON.parse(response.body)["value"]["error_code"]
      expect(retval).to eq(ErrorEnum::PUBLIC_NOTICE_STATUS_ERROR)
    end

    after(:all) do
      clear(:PublicNotice)
    end
  end

  describe "visit /update" do
    before(:each) do
      @public_notice = FactoryGirl.create(:public_notice)
    end

    it "should return true" do
      public_notice = {}
      public_notice["title"] = "spec_test"
      public_notice["content"] = "test"
      public_notice["status"] = 2
      put "admin/public_notices/#{@public_notice.id}",
        JSON.dump(
            public_notice: public_notice,
            auth_key: @auth_key),
        "CONTENT_TYPE" => "application/json"
      response.status.should be(200)
      retval = JSON.parse(response.body)["value"]
      expect(retval).to eq(true)
      pn = PublicNotice.find_by_id(@public_notice.id)
      expect(pn.title).to eq("spec_test")
    end

    it "should return PUBLIC_NOTICE_NOT_EXIST" do
      public_notice = @public_notice.attributes
      public_notice["status"] = 4
      put "admin/public_notices/#{@public_notice.id}",
        JSON.dump(
            public_notice: public_notice,
            auth_key: @auth_key),
        "CONTENT_TYPE" => "application/json"
      response.status.should be(200)
      retval = JSON.parse(response.body)["value"]["error_code"]
      expect(retval).to eq(ErrorEnum::PUBLIC_NOTICE_STATUS_ERROR)
    end

    after(:each) do
      clear(:PublicNotice)
    end
  end

  describe "visit /create" do
    before(:each) do
      @public_notice = FactoryGirl.create(:public_notice)
    end

    it "should return true" do
      delete "admin/public_notices/#{@public_notice.id}",
        auth_key: @auth_key
      response.status.should be(200)
      retval = JSON.parse(response.body)["value"]
      expect(retval).to eq(true)
    end

    it "should return PUBLIC_NOTICE_NOT_EXIST" do
      delete "admin/public_notices/#{@public_notice.id.to_s.next}",
        auth_key: @auth_key
      response.status.should be(200)
      retval = JSON.parse(response.body)["value"]["error_code"]
      expect(retval).to eq(ErrorEnum::PUBLIC_NOTICE_NOT_EXIST)
    end

    after(:each) do
      clear(:PublicNotice)
    end
  end

  after(:all) do
    clear(:User)
  end

end
