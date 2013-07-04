require 'spec_helper'

describe "sessions controller" do

  before(:each) do
    @user = FactoryGirl.create(:admin_another)
  end

  describe "visit /session" do
    it "should return USER_NOT_EXIST when email not exist" do
      post '/sessions',
        email_mobile: "none@test.com",
        password: 123456,
        keep_sign_in: true
      response.status.should be(200)
      retval = JSON.parse(response.body)["value"]["error_code"]
      expect(retval).to eq(ErrorEnum::USER_NOT_EXIST)
    end

    it "should return USER_NOT_EXIST when mobile not exist" do
      post '/sessions',
        email_mobile: "17283748573",
        password: 123456,
        keep_sign_in: true
      response.status.should be(200)
      retval = JSON.parse(response.body)["value"]["error_code"]
      expect(retval).to eq(ErrorEnum::USER_NOT_EXIST)
    end 

    it "should return USER_NOT_EXIST when user is a illegal value" do
      post '/sessions',
        email_mobile: "test0101",
        password: 123456,
        keep_sign_in: true
      response.status.should be(200)
      retval = JSON.parse(response.body)["value"]["error_code"]
      expect(retval).to eq(ErrorEnum::USER_NOT_EXIST)
    end

    it "should return USER_NOT_REGISTERED when user status is 0" do
      @user.status = 0
      @user.save
      post '/sessions',
        email_mobile: @user.email,
        password: 123456,
        keep_sign_in: true
      response.status.should be(200)
      retval = JSON.parse(response.body)["value"]["error_code"]
      expect(retval).to eq(ErrorEnum::USER_NOT_REGISTERED)
    end

    it "should return USER_NOT_ACTIVATED when user status is 1" do
      @user.status = 1
      @user.save
      post '/sessions',
        email_mobile: @user.email,
        password: 123456,
        keep_sign_in: true
      response.status.should be(200)
      retval = JSON.parse(response.body)["value"]["error_code"]
      expect(retval).to eq(ErrorEnum::USER_NOT_ACTIVATED)
    end

    it "should return USER_NOT_EXIST when password wrong" do
      post '/sessions',
        email_mobile: @user.email,
        password: 12345,
        keep_sign_in: true
      response.status.should be(200)
      retval = JSON.parse(response.body)["value"]["error_code"]
      expect(retval).to eq(ErrorEnum::WRONG_PASSWORD)
    end

    it "should return USER_NOT_EXIST when password wrong" do
      @user.lock = true
      @user.save
      post '/sessions',
        email_mobile: @user.email,
        password: 123456,
        keep_sign_in: true
      response.status.should be(200)
      retval = JSON.parse(response.body)["value"]["error_code"]
      expect(retval).to eq(ErrorEnum::USER_LOCKED)
    end

    it "should return a auth_key with email" do
      post '/sessions',
        email_mobile: @user.email,
        password: 123456,
        keep_sign_in: true
      response.status.should be(200)
      retval = JSON.parse(response.body)["value"]
      expect(retval.keys).to eq(["auth_key"])
    end

    it "should return a auth_key with mobile" do
      post '/sessions',
        email_mobile: @user.mobile,
        password: 123456,
        keep_sign_in: true
      response.status.should be(200)
      retval = JSON.parse(response.body)["value"]
      expect(retval.keys).to eq(["auth_key"])
    end

    it "should return a auth_key and third_party_user_id bind" do
      sina_user = FactoryGirl.create(:sina_user)
      post '/sessions',
        email_mobile: @user.email,
        password: 123456,
        keep_sign_in: true,
        third_party_user_id: sina_user.id
      response.status.should be(200)
      retval = JSON.parse(response.body)["value"]
      expect(retval.keys).to eq(["auth_key"])
      expect(User.find_by_id(@user.id).third_party_users.find_by_id(sina_user.id.to_s)).to eq(sina_user)
    end
  end

  describe "visit /login_with_auth_key" do
    before(:each) do
      post '/sessions',
        email_mobile: @user.email,
        password: 123456,
        keep_sign_in: true
      @auth_key = JSON.parse(response.body)["value"]["auth_key"]
    end

    it "should renturn ErrorEnum::AUTH_KEY_NOT_EXIST when auth_key not exist" do
      post "/sessions/login_with_auth_key",
        auth_key: @auth_key.to_s.next
      response.status.should be(200)
      retval = JSON.parse(response.body)["value"]["error_code"]
      expect(retval).to eq(ErrorEnum::AUTH_KEY_NOT_EXIST)
    end

    it "should renturn true" do
      post "/sessions/login_with_auth_key",
        auth_key: @auth_key.to_s
      response.status.should be(200)
      retval = JSON.parse(response.body)["value"]
      expect(retval["user_id"]).to eq(@user.id.to_s)
    end
  end

  describe "visit /destroy" do

    it "should return true" do
      delete "/sessions"
      response.status.should be(302)
    end

    it "should return true" do
      post '/sessions',
        email_mobile: @user.email,
        password: 123456,
        keep_sign_in: true
      @auth_key = JSON.parse(response.body)["value"]["auth_key"]
      delete "/sessions",
        auth_key: @auth_key
      response.status.should be(200)
      retval = JSON.parse(response.body)["value"]
      expect(true).to eq(true)
    end
  end

  after(:each) do
    clear(:User)
  end

end
