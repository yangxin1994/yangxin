require 'spec_helper'

describe "sample attribute management" do

	it "create sample attribute" do
		post "/admin/advertisements",
			sample_attribute: {name: "gender",
				type: 8}
		response.status.should be(200)
		JSON.parse(response.body)["value"]["error_code"].should be(ErrorEnum::WRONG_SAMPLE_ATTRIBUTE_TYPE)
	end

=begin
	it "" do
		sample = FactoryGirl.create(:sample)

		# email already exists
		post "/registrations",
			:user_type => 0
			:user => {:email => "test@oopsdata.com",
				:password => "123456",
				:password_confirmation => "123456"}
		response.status.should be(200)
		JSON.parse(response.body)["value"]["error_code"].should be(ErrorEnum::USER_EXIST)

		# mobile already exists
		post "/registrations",
			:user_type => 0
			:user => {:mobile => "13800000000",
				:password => "123456",
				:password_confirmation => "123456"}
		response.status.should be(200)
		JSON.parse(response.body)["value"]["error_code"].should be(ErrorEnum::USER_EXIST)

		# password confirmation is not the same as password
		post "/registrations",
			:user_type => 0
			:user => {:email => "test1@oopsdata.com",
				:password => "123456",
				:password_confirmation => "1"}
		response.status.should be(200)
		JSON.parse(response.body)["value"]["error_code"].should be(ErrorEnum::WRONG_PASSWORD_CONFIRMATION)

		# successfully registrates with email
		post "/registrations",
			:user_type => 0
			:user => {:email => "test1@oopsdata.com",
				:password => "123456",
				:password_confirmation => "123456"}
		response.status.should be(200)
		JSON.parse(response.body)["value"].should be(true)
		user = User.find_by_email("test1@oopsdata.com")
		user.status.should be(User::REGISTERED)

		# successfully registrates with mobile
		post "/registrations",
			:user_type => 0
			:user => {:email => "13800000001",
				:password => "123456",
				:password_confirmation => "123456"}
		response.status.should be(200)
		JSON.parse(response.body)["value"].should be(true)
		user = User.find_by_mobile("13800000001")
		user.status.should be(User::REGISTERED)
	end
=end
end
