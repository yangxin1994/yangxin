# coding: utf-8
require 'test_helper'

class SurveyTest < ActiveSupport::TestCase
  setup do
    clear(Survey)
    @survey_with_issue = FactoryGirl.create(:survey_with_issue)
    @answer_with_issue = FactoryGirl.create(:answer_with_issue)
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
    # @survey_with_issue.all_questions.each do |q|
    #   pp q.header 1
    # end
    #p @survey_with_issue.csv_header.to_csv
    # pp @survey_with_issue.spss_header
    
    # p Encoding.default_external
    # p Encoding.default_internal
    #@answer_with_issue.csv_content
    #@answer_with_issue.load_csv
    @survey_with_issue.answer_import("")
    #@survey_with_issue.connect_sinatra
    assert true
  end
end