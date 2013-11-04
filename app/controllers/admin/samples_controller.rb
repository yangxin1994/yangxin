# encoding: utf-8
# already tidied up
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
      success_true sample.operate_point(params[:amount], params[:remark])
    end  
  end

  def set_sample_role
    render_json User.where(:_id => params[:id]).first do |sample|
      {
        :role => sample.set_sample_role(params[:roles].map(&:to_i)),
        :block => sample.block(params[:block]),
        :active => sample.update_attributes(:email => params[:email],
        :email_activation => params[:email_activation] == "true",
        :mobile => params[:mobile],
        :mobile_activation => params[:mobile_activation] == "true")
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
    @redeem_log = auto_paginate(@sample.logs.redeem_logs)
  end

  def point_log
    @sample = User.find(params[:id])
    @point_log = auto_paginate(@sample.logs.point_logs)
  end

  def lottery_log
    @sample = User.find(params[:id])
    @lottery_log = auto_paginate(@sample.logs.lottery_logs)
  end

  def answer_log
    @sample = User.find(params[:id])
    @answers = @sample.answers.not_preview.desc(:created_at)
    @answers = auto_paginate(@answers) do |paginated_answers|
      paginated_answers.map { |e| e.info_for_admin }
    end

    data = @answers['data'].map do |item|
      # Need attrs: rewards, answer_status, answer_id, amount
      # maybe it has too many attrs, so i did not use helper method.
      # select reward
      item["select_reward"] = ""
      # 
      item["free_reward"] = item.rewards.to_a.empty?
      item.rewards.to_a.each do |rew|
        # if rejected, reward in empty
        item["select_reward"] = "" and break if item.status.to_i == 2 

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
    @answers = auto_paginate(@answers)
    
    data = @answers['data'].map do |item|
      a = Answer.find_by_id(item._id)
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

  def all_attributes
    render_json true do |survey|
      SampleAttribute.normal.order_by(:type)
    end    
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
    when DataType::STRING
    when DataType::ENUM
    when DataType::NUMBER
      # attr['value_2'] = attr["analyze_requirement"]['segmentation'].map{|es| es.map { |e| e.join(',') }}.join("\n")
      attr['value_2'] = attr["analyze_requirement"]['segmentation'].join(' ')
    when DataType::DATE
      attr['date_type_3'] = attr["date_type"]
      strf = case attr[:date_type]
      when 1 then "%Y/%m"
      when 0 then "%Y"
      else "%Y/%m/%d"
      end      
      # attr['value_3'] = attr["analyze_requirement"]['segmentation'].map{|es| es.map { |e| e.strftime("%Y/%m/%d") }}.join("\n")
      attr['value_3'] = attr["analyze_requirement"]['segmentation'].map{|e| Time.at(e).strftime(strf) }.join(" ")
    when DataType::NUMBER_RANGE
      # attr['value_4'] = attr["analyze_requirement"]['segmentation'].map{|es| es.map { |e| e.join(',') }}.join("\n")
      attr['value_4'] = attr["analyze_requirement"]['segmentation'].join(' ')
    when DataType::DATE_RANGE
      attr['date_type_5'] = attr["date_type"]
      strf = case attr[:date_type]
      when 1 then "%Y/%m"
      when 0 then "%Y"
      else "%Y/%m/%d"
      end      
      # attr['value_5'] = attr["analyze_requirement"]['segmentation'].map{|es| es.map { |e| e.strftime("%Y/%m/%d") }}.join("\n")
      attr['value_5'] = attr["analyze_requirement"]['segmentation'].map{|e| Time.at(e).strftime(strf) }.join(" ")
    when DataType::ADDRESS
    when DataType::ARRAY
      attr['element_type'] = attr["element_type"]
      attr['enum_array_6'] = attr["enum_array"]
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
    when DataType::STRING
    when DataType::ENUM
      attr[:enum_array] = attr[:enum_array].split(' ')
    when DataType::NUMBER
      attr[:analyze_requirement][:segmentation] = attr[:value_2].split(' ').map { |e| e.to_f }
    when DataType::DATE
      attr[:date_type] = attr[:date_type_3].to_i
      strf = case attr[:date_type]
      when 1 then "-1"
      when 0 then "-1-1"
      else ""
      end
      set_attr[:analyze_requirement][:segmentation] = attr[:value_3].split(' ').map { |e| Time.parse("#{e}#{strf}").to_i }
    when DataType::NUMBER_RANGE
      set_attr[:analyze_requirement][:segmentation] = attr[:value_4].split(' ').map { |e| e.to_f }
    when DataType::DATE_RANGE
      attr[:date_type] = attr[:date_type_5].to_i
      strf = case attr[:date_type]
      when 1 then "-1"
      when 0 then "-1-1"
      else ""
      end
      attr[:analyze_requirement][:segmentation] = attr[:value_5].split(' ').map { |e| Time.parse("#{e}#{strf}").to_i }
    when DataType::ADDRESS
    when DataType::ARRAY
      attr[:element_type] = attr[:element_type].to_i
      attr[:enum_array] = attr[:enum_array_6].split(' ')
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
