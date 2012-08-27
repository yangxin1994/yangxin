# coding: utf-8
require 'test_helper'

class SurveyTest < ActiveSupport::TestCase
	setup do
		clear(Survey)
		@survey_with_issue = FactoryGirl.create(:survey_with_issue)
	#FactoryGirl.create(:single_choice_question)
	end

	test "should show a header of csv" do
		#pp @survey_with_issue
		#pp Question.first
		@survey_with_issue.all_questions.each { |i| p i.attributes['_id'] }
		pp Question.issue
		#pp Question.first.header 1
		assert true
	end
end