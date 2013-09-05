require 'spec_helper'

describe "registrations controller" do

  describe "visit /registrations" do

    it "should return ILLEGAL_EMAIL_OR_MOBILE when account error" do
      post "/registrations",
        email_mobile: 12324435,
        password: 123456
      response.status.should be(200)
      retval = JSON.parse(response.body)["value"]["error_code"]
      expect(retval).to eq(ErrorEnum::ILLEGAL_EMAIL_OR_MOBILE)
    end

    it "should return EMAIL_OR_MOBILE_EXIST when user exist" do
      user = FactoryGirl.create(:admin_another)
      post "/registrations",
        email_mobile: user.email,
        password: 123456
      response.status.should be(200)
      retval = JSON.parse(response.body)["value"]["error_code"]
      expect(retval).to eq(ErrorEnum::EMAIL_OR_MOBILE_EXIST)
    end

    it "should return EMAIL_OR_MOBILE_EXIST when user exist" do
      user = FactoryGirl.create(:admin_another)
      post "/registrations",
        email_mobile: user.mobile,
        password: 123456
      response.status.should be(200)
      retval = JSON.parse(response.body)["value"]["error_code"]
      expect(retval).to eq(ErrorEnum::EMAIL_OR_MOBILE_EXIST)
    end

    it "should return true" do
      sina_user = FactoryGirl.create(:sina_user)
      expect(SinaUser.find_by_id(sina_user.id).user).to eq(nil)
      user = FactoryGirl.create(:admin_another)
      user.password = nil
      user.save
      post "/registrations",
        email_mobile: user.mobile,
        password: 123456,
        third_party_user_id: sina_user.id
      response.status.should be(200)
      retval = JSON.parse(response.body)["value"]
      expect(retval).to eq(true)
      expect(SinaUser.find_by_id(sina_user.id).user.class).to eq(User)
    end

    it "should return true" do
      post "/registrations",
        email_mobile: "test@test.com",
        password: 123456
      response.status.should be(200)
      retval = JSON.parse(response.body)["value"]
      expect(retval).to eq(true)
    end
  end

  describe "visit /email_activate" do

    it "should return true " do
      sample = FactoryGirl.create(:sample)
      sample.status = 1
      sample.save
      ak = Encryption.encrypt_activate_key({"email" => sample.email, "time" => Time.now.to_i}.to_json)
      post "/registrations/email_activate",
        activate_key: ak
      response.status.should be(200)
      retval = JSON.parse(response.body)["value"]
      expect(retval.keys).to eq(["auth_key"])
      expect(User.find_by_id(sample.id.to_s).email_activation).to eq(true)
    end
  end

  describe "visit /mobile_activate" do

    it "should return true " do
      sample = FactoryGirl.create(:sample)
      sample.status = 1
      sample.sms_verification_code = 123123
      sample.sms_verification_timeout = Time.now.to_i + 86400
      sample.save
      post "/registrations/mobile_activate",
        mobile: sample.mobile,
        password: 123456,
        verification_code: 123123
      response.status.should be(200)
      retval = JSON.parse(response.body)["value"]
      expect(retval.keys).to eq(["auth_key"])
      expect(User.find_by_id(sample.id.to_s).mobile_activation).to eq(true)
    end
  end


  after(:each) do
      clear(:User)
    end

end
