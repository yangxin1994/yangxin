# encoding: utf-8
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
    @sample = User.find(params[:id]).sample_attributes
  end

  def show
    @attrs = User.find(params[:id]).sample_attributes
    @sample_attributes = SampleAttribute.normal.map do |sample_attribute|
      {
        'name' => sample_attribute[:name],
        'type' => sample_attribute[:type],
        'element_type' => sample_attribute[:element_type],
        'enum_array' => sample_attribute[:enum_array],
        'date_type' => sample_attribute[:date_type],
        'status' => sample_attribute[:status],
        'completion' => sample_attribute[:completion],
        'analyze_requirement' => sample_attribute[:analyze_requirement],
        'analyze_result' => sample_attribute[:analyze_result],
        '_id' => sample_attribute[:_id]
      }
    end
    @sample_attributes.each do |sample_attribute|
      sample_attribute['value'] = @attrs[sample_attribute['name']]
    end
  end
  # ##########################
  #
  # index当页操作相关
  #
  # ##########################

  def operate_point
    render_json User.where(:_id => params[:id]).first do |sample|
      sample.operate_point(params[:amount], params[:remark])
    end  
  end

  def set_sample_role
    render_json User.where(:_id => params[:id]).first do |sample|
      {
        :role => sample.set_sample_role(params[:roles].map(&:to_i)),
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
    @sample = User.find(params[:id])
    @redeem_log = auto_paginate(@sample.logs.redeem_logs) do |logs|
      logs.map { |e| e.info_for_admin }
    end
  end

  def point_log
    @sample = User.find(params[:id])
    @point_log = auto_paginate(@sample.logs.point_logs) do |logs|
      logs.map { |e| e.info_for_admin }
    end
  end

  def lottery_log
    @sample = User.find(params[:id])
    @lottery_log = auto_paginate(@sample.logs.lottery_logs) do |logs|
      logs.map { |e| e.info_for_admin }
    end
  end

  def answer_log
    @answers = @current_user.answers.not_preview.desc(:created_at)
    @answers = auto_paginate(@answers) do |paginated_answers|
      paginated_answers.map { |e| e.info_for_admin }
    end
    data = @answers['data'].map do |item|
      # Need attrs: rewards, answer_status, answer_id, amount
      # maybe it has too many attrs, so i did not use helper method.
      # select reward
      item["select_reward"] = ""
      # 
      item["free_reward"] = item["rewards"].to_a.empty?
      item["rewards"].to_a.each do |rew|
        # if rejected, reward in empty
        item["select_reward"] = "" and break if item["answer_status"].to_i == 2 

        if rew["checked"]
          case rew["type"].to_i
          when 1
            item["select_reward"] = "#{rew["amount"].to_i}元话费"
          when 2
            item["select_reward"] = "#{rew["amount"].to_i}元支付宝"
          when 4 
            item["select_reward"] = "#{rew["amount"].to_i}积分"
          when 8
            item["select_reward"] = "抽奖机会"
          when 16
            item["select_reward"] = "#{rew["amount"].to_i}集分宝"
          end

          break
        end
      end
      # return
      item 
    end
    @answers['data'] = data
  end

  def spread_log
    @sample = User.find(params[:id])
    @answers = Answer.not_preview.finished.where(:introducer_id => @sample._id.to_s)
    @answers = auto_paginate(@answers) do |paginated_answers|
      paginated_answers.map { |e| e.info_for_admin }
    end
    data = @answers['data'].map do |item|
      a = Answer.find_by_id(item["answer_id"])
      if a.user.present?
        item["sample_email_mobile"] = a.user.email || a.user.mobile
      else
        item["sample_email_mobile"] = "游客"
      end
      item
    end
    @answers['data'] = data
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
    @sample_count = User.count_sample(params[:period].to_s, params[:time_length].to_i)
    data = User.count_sample('day', 2)['new_sample_number']
    @new_user_by_day = data[1] - data[0]
    data = User.count_sample('week', 2)['new_sample_number']
    @new_user_by_week = data[1] - data[0]
    data = User.count_active_sample('day', 1)
    @active_user_by_day = data[0]
    data = User.count_active_sample('week', 1)
    @active_user_by_week = data[0]
  end

  def get_sample_count
    render_json User.count_sample(params[:period].to_s, params[:time_length].to_i)
  end

  def get_active_sample_count
    retval = User.count_active_sample(params[:period], params[:time_length].to_i)
    render_json retval and return
  end

  def send_message
    render_json current_user.create_message(params[:title], params[:content], params[:sample_ids])
  end

end
