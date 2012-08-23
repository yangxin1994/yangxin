# coding: utf-8
require 'test_helper'

class SurveyTest < ActiveSupport::TestCase
	setup do
		clear(Survey)
		@survey_with_issue = FactoryGirl.create(:survey_with_issue)
	#FactoryGirl.create(:single_choice_question)
	end

	test "01 should get rule arr from check_quota" do
		#pp @survey_with_issue
		#pp Question.first
		@survey_with_issue.all_questions.each { |i| p i.attributes['_id'] }
		assert true
	end
end