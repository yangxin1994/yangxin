# coding: utf-8
require 'test_helper'

class SurveyTest < ActiveSupport::TestCase
  setup do
    clear(Survey)
    @survey_with_issue = FactoryGirl.create(:survey_with_issue)
    @answer_with_issue = FactoryGirl.create(:answer_with_issue)
    @survey_with_issue.answers << @answer_with_issue
    3000.times do
        @survey_with_issue.answers << FactoryGirl.create(:answer_with_issue)
    end
    p "###### Ready !!! ######"
  #FactoryGirl.create(:single_choice_question)
  end

  test "should show a header of csv" do
    #pp @survey_with_issue
    #pp Question.first
    #@survey_with_issue.all_questions.each { |i| p i.attributes['_id'] }
    #pp Question.first.issue
    # pp Question.first.issue["max_choice"]
    # pp Surver.first.header 1
    # pp Question.first.header 2
    # p @survey_with_issue.csv_header.to_csv
    # pp @survey_with_issue.spss_header
    
    # p Encoding.default_external
    # p Encoding.default_internal
    # p @survey_with_issue.answer_content.to_csv
    #@survey_with_issue.export_csv
    #pp @survey_with_issue.answer_import("")
    @survey_with_issue.send_spss_data
    assert true
  end
end