#encoding: utf-8
require 'error_enum'
class EntryClerk::SurveysController < EntryClerk::ApplicationController
    
  def csv_header
    survey = Survey.find_by_id(params[:id])
    render_json !!survey do |s|
      if s
        survey.csv_header(:with => "import_id", :text => true)
      else
        { :error_code => ErrorEnum::SURVEY_NOT_EXIST, 
          :error_message => "survey not exist"}
      end
    end
  end

  def import_answer
    survey = Survey.find_by_id(params[:id])
    # csv = Marshal::load(params[:csv])
    render_json !!survey do |s|
      if s
        c = params[:csv]
        if params[:csv].is_a? Array
          c = params[:csv].join
        end
        if result = survey.answer_import(c)
          result
        else
          @is_success = false
          {
            :error_code => ErrorEnum::WRONG_ANSWERS,
            :error_message => "wrong answers"
          }
        end
      else
        { :error_code => ErrorEnum::SURVEY_NOT_EXIST, 
          :error_message => "问卷不存在"}
      end
    end
  end
end
