#encoding: utf-8
# finish migrating
require "csv"
require 'string/utf8'
class Quill::ResultsController < Quill::QuillController

  before_filter :ensure_survey, :only => [:show, :excel, :spss, :csv_header, :import_data, :report]

  def initialize
    super(4)
  end

  # PAGE: show result
  def show
    @hide_left_sidebar = true

    @survey_questions = get_survey_questions

    @filters = @survey.filters || []

    @filter_index = params[:fi].to_i
    @filter_index = (@filters.length - 1) if @filter_index > @filters.length
    @filter_index = 0 if @filter_index < 0

    @include = params[:i].to_b

    @job_id = @survey.analysis(@filter_index-1, @include)

    @reports = @survey.list_report_mockups

  end

  # AJAX
  def excel
    retval = @survey.to_excel(params[:analysis_task_id])
    render_json_auto retval and return
  end

  def spss
    retval = @survey.to_spss(params[:analysis_task_id])
    render_json_auto retval and return
  end

  # AJAX
  def report
    retval = @survey.report(params[:analysis_task_id], params[:report_mockup_id], params[:report_style].to_i, params[:report_type])
    render_json_auto retval and return
  end

  # PAGE, csv header
  def csv_header
    result = @survey.csv_header(:with => "import_id", :text => true)
    send_data(result, :filename => "导入数据-#{@survey._id}.csv", :type => 'text/csv')
  end

  # AJAX import csv data file
  def import_data
    unless(File.exist?("public/uploads"))
      Dir.mkdir("public/uploads")
    end
    unless(File.exist?("public/uploads/csv"))
      Dir.mkdir("public/uploads/csv")
    end
    csv_origin = params["import_file"]
    filename = Time.now.strftime("%s")+'_'+(csv_origin.original_filename)
    File.open("public/uploads/csv/#{filename}", "wb") do |f|
      f.write(csv_origin.read)
    end
    csv = File.read("public/uploads/csv/#{filename}").utf8!
    result = @survey.answer_import(csv)
    if result[:error]
      csv_file = CSV.open("public/uploads/csv/error_#{filename}", "wb") do |csv|
        result[:error].each {|a| csv << a}
      end
      result[:error] = "uploads/csv/error_#{filename}"
    end
    render_json_auto result and return
  end
end