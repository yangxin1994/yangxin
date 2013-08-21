require 'string/utf8'
class Admin::SamplesController < Admin::AdminController

  layout "layouts/admin-todc"

  before_filter :require_sign_in

  def index
    if params[:keyword]
      if params[:keyword] =~ /^.+@.+$/
        params[:email] = params[:keyword]
      else
        params[:mobile] = params[:keyword]
      end
    end
    @samples = auto_paginate(User.search_sample(params[:email], params[:mobile], params[:is_block].to_s == "true"))
  end

  def edit
    @sample = Sample.sample.find(params[:id]).sample_attributes
  end

  def show
    @sample = Sample.sample.find(params[:id]).sample_attributes
  end
  # ##########################
  #
  # index当页操作相关
  #
  # ##########################

  def operate_point
    render_json Sample.where(:_id => params[:id]).first do |sample|
      sample.operate_point(params[:amount], params[:remark])
    end  
  end

  def set_sample_role
    render_json Sample.where(:_id => params[:id]).first do |sample|
      {
        :role => sample.set_sample_role(params[:role]),
        :block => sample.block(params[:block])
      }
    end
  end

  # ##########################
  #
  # 样本日志相关
  #
  # ##########################
  def redeem_log
    @sample = Sample.sample.find(params[:id])
    @redeem_log = auto_paginate(@sample.logs.point_logs) do |logs|
      logs.map { |e| e.info_for_admin }
    end
  end

  def point_log
    @sample = Sample.sample.find(params[:id])
    @point_log = auto_paginate(@sample.logs.point_logs) do |logs|
      logs.map { |e| e.info_for_admin }
    end
  end

  def lottery_log
    @sample = Sample.sample.find(params[:id])
    @lottery_log = auto_paginate(@sample.logs.lottery_logs) do |logs|
      logs.map { |e| e.info_for_admin }
    end
  end

  def answer_log
    @sample = Sample.sample.find(params[:id])
    @answer_log = auto_paginate(@sample.logs.answer_logs) do |logs|
      logs.map { |e| e.info_for_admin }
    end
  end

  def spread_log
    @sample = Sample.sample.find(params[:id])
    @spread_log = auto_paginate(@sample.logs.spread_logs) do |logs|
      logs.map { |e| e.info_for_admin }
    end
  end
  # ##########################
  #
  # 样本属性相关
  #
  # ##########################
  def attributes
    @attributes = auto_paginate SampleAttribute.search(params[:name])
  end

  def add_attributes
    params[:attribute][:type] = params[:attribute][:type].to_i
    attrs = make_attrs params[:attribute]
    if params[:attribute][:id].present?
      SampleAttribute.normal.find(params[:attribute][:id]).update_sample_attribute(attrs)
      redirect_to "/admin/samples/#{params[:attribute][:id]}/edit_attributes"
    else
      SampleAttribute.create_sample_attribute(attrs)
      redirect_to "/admin/samples/attributes"
    end
  end

  def new_attributes
    @attribute = {}
  end

  def edit_attributes
    attr = SampleAttribute.normal.find(params[:id])
    if attr["enum_array"].is_a? Array
      attr['enum_array'] = attr["enum_array"].join("\n")
    end
    attr["analyze_requirement"]['segmentation'] ||= []
    case attr['type'].to_i
    when 0
      attr['value_0'] = attr["analyze_requirement"]['segmentation']
    when 1
      attr['value_1'] = attr["analyze_requirement"]['segmentation']
    when 2
      attr['value_2'] = attr["analyze_requirement"]['segmentation'].map{|es| es.map { |e| e.join(',') }}.join("\n")
    when 3
      attr['date_type_3'] = attr["date_type"]
      attr['value_3'] = attr["analyze_requirement"]['segmentation'].map{|es| es.map { |e| e.strftime("%Y/%m/%d") }}.join("\n")
    when 4
      attr['value_4'] = attr["analyze_requirement"]['segmentation'].map{|es| es.map { |e| e.join(',') }}.join("\n")
    when 5
      attr['date_type_5'] = attr["date_type"]
      attr['value_5'] = attr["analyze_requirement"]['segmentation'].map{|es| es.map { |e| e.strftime("%Y/%m/%d") }}.join("\n")
    when 6
      attr['value_6'] = attr["analyze_requirement"]['segmentation']
    when 7
      attr['element_type'] = attr["element_type"]
      attr['enum_array_6'] = attr["enum_array"]
      attr['value_7'] = attr["analyze_requirement"]['segmentation']
    end
    @attribute = attr
  end

  def destroy_attributes
    render_json SampleAttribute.normal.where(:_id => params[:id]) do |attribute|
      attribute.delete
    end
  end

  def make_attrs(attr)
    attr[:analyze_requirement] = {}
    case attr[:type]
    when 0
      attr[:analyze_requirement][:segmentation] = attr[:value_0].split(' ')
    when 1
      attr[:enum_array] = attr[:enum_array].split(' ')
      attr[:analyze_requirement][:segmentation] = attr[:value_1].split(' ')
    when 2
      attr[:analyze_requirement][:segmentation] = attr[:value_2].split(' ').map { |e| e.split(',') }
    when 3
      attr[:date_type] = attr[:date_type_3].to_i
      attr[:analyze_requirement][:segmentation] = attr[:value_3].split(' ').map { |e| Time.parse(e.split(',')).to_i }
    when 4
      attr[:analyze_requirement][:segmentation] = attr[:value_4].split(' ').map { |e| e.split(',') }
    when 5
      attr[:date_type] = attr[:date_type_5].to_i
      attr[:analyze_requirement][:segmentation] = attr[:value_5].split(' ').map { |e| Time.parse(e.split(',')).to_i }
    when 6
      attr[:analyze_requirement][:segmentation] = attr[:value_6].split(' ')
    when 7
      attr[:element_type] = attr[:element_type].to_i
      attr[:enum_array] = attr[:enum_array_6].split(' ')
      attr[:analyze_requirement][:segmentation] = attr[:value_7].split(' ')
    end
    attr
  end

  # ##########################
  #
  # 样本数据统计
  #
  # ##########################
  def status
    _client = Admin::SampleClient.new(session_info)
    @sample_count = _client.get_sample_count.value
    data = _client.get_sample_count('day', 2).value['new_sample_number']
    @new_user_by_day = data[1] - data[0]
    data = _client.get_sample_count('week', 2).value['new_sample_number']
    @new_user_by_week = data[1] - data[0]
    data = _client.get_active_sample_count('day', 1).value
    @active_user_by_day = data[0]
    data = _client.get_active_sample_count('week', 1).value
    @active_user_by_week = data[0]
  end

  def get_sample_count
    _client = Admin::SampleClient.new(session_info)
    render json: _client.get_sample_count(params[:period], params[:time_length]).value
  end

  def get_active_sample_count
    _client = Admin::SampleClient.new(session_info)
    render json: _client.get_active_sample_count(params[:period], params[:time_length]).value
  end

  def send_message
    result = @samples_client.send_message(params)
    render :json => result
  end

end