require 'spec_helper'

describe 'surveys' do

	before(:each) do
		clear(:Survey)
	end

	it 'list surveys' do
		s1 = FactoryGirl.create(:survey)
		s2 = FactoryGirl.create(:survey)
		s3 = FactoryGirl.create(:survey)

		s1.status = 2
		s1.save
		s2.status = 1
		s2.save
		s3.status = 2
		s3.save

		get "/agent/surveys"
		response.status.should be(200)
		retval = JSON.parse(response.body)["value"]
		returned_survey_ids = retval.map { |e| e["_id"] }
		returned_survey_ids.should include s1._id.to_s
		returned_survey_ids.should include s3._id.to_s
	end
end
