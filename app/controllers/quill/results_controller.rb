#encoding: utf-8
require "csv"
require 'string/utf8'
class Quill::ResultsController < Quill::QuillController

  before_filter :ensure_survey, :only => [:show]

  def initialize
    super(4)
  end

  # PAGE: show result
  def show
    @hide_left_sidebar = true

    @survey_questions = get_survey_questions
    @filters = @survey['filters'] || []

    @filter_index = params[:fi].to_i
    @filter_index = (@filters.length - 1) if @filter_index > @filters.length
    @filter_index = 0 if @filter_index < 0

    @include = params[:i].to_b

    @job_id = Quill::ResultClient.new(session_info).analysis(@survey['_id'], @filter_index - 1, @include)
    if @job_id.success
    	@job_id = @job_id.value
    else
    	if @job_id.value['error_code'] == 'error_7'
	    	# when quillweb is signin while quill is signout
	    	redirect_to signout_path({ref: request.url}) and return
	    else
	    	@job_id = nil
	    end
    end
    # @job_id.success ? @job_id = @job_id.value : @job_id = nil

    @reports = Quill::ReportMockupClient.new(session_info, params[:questionaire_id]).index
    @reports.success ? @reports = @reports.value : @reports = nil
  end

  # AJAX
  def excel
    render :json => Quill::ResultClient.new(session_info).to_excel(params[:questionaire_id], params[:analysis_task_id])
  end
  def spss
    render :json => Quill::ResultClient.new(session_info).to_spss(params[:questionaire_id], params[:analysis_task_id])
  end

  # AJAX
  def report
    render :json => Quill::ResultClient.new(session_info).report(params[:questionaire_id],
      params[:report_mockup_id], params[:report_style].to_i, params[:report_type],
      params[:analysis_task_id])
  end

  # PAGE, csv header
  def csv_header
    id = params[:questionaire_id]
    result = Quill::ResultClient.new(session_info).csv_header(id)
    if result.success
      send_data(result.value.to_csv, :filename => "导入数据-#{id}.csv", :type => 'text/csv')
    else
    	if result.require_login?
    		render :text => '请先登录后再下载表头'
    	else
      	render :text => '下载表头出错'
      end
    end
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
    filename = Time.now.strftime("%y-%m-%s-%d")+'_'+(csv_origin.original_filename)
    File.open("public/uploads/csv/#{filename}", "wb") do |f|
      f.write(csv_origin.read)
    end
    # csv = CSV.open("public/uploads/as.csv", :headers => true)
    csv = File.read("public/uploads/csv/#{filename}").utf8!
    render :json => Quill::ResultClient.new(session_info).import_answer(params[:questionaire_id], csv)
  end

end