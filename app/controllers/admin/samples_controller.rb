require 'string/utf8'
class Admin::SamplesController < Admin::AdminController

  layout "layouts/admin-todc"

  before_filter :require_sign_in

  before_filter :get_samples_client

  def get_samples_client
    @samples_client = Admin::SampleClient.new(session_info)
  end

  def index
    result = @samples_client.index(params)
    if result.success
      @samples = result.value
    else
      render :json => result
    end
  end

  def edit
    result = @samples_client.edit(params[:id])
    if result.success
      @sample = result.value
    else
      render :json => result
    end
  end

  def show
    @sample = @samples_client.show(params[:id])
    gon.push({:sample => @sample})
  end
  # ##########################
  #
  # index当页操作相关
  #
  # ##########################

  def operate_point
    render :json => @samples_client.operate_point(params)
  end

  def set_sample_role
    render :json => @samples_client.set_sample_role(params)
  end

  # ##########################
  #
  # 样本日志相关
  #
  # ##########################
  def redeem_log
    result = @samples_client.redeem_log(params)
    if result.success
      @redeem_log = result.value
    else
      render :json => result
    end
  end

  def point_log
    result = @samples_client.point_log(params)
    if result.success
      @point_log = result.value
    else
      render :json => result
    end
  end

  def lottery_log
    result = @samples_client.lottery_log(params)
    if result.success
      @lottery_log = result.value
    else
      render :json => result
    end
  end

  def answer_log
    result = @samples_client.answer_log(params)
    if result.success
      @answer_log = result.value
    else
      render :json => result
    end
  end

  def spread_log
    result = @samples_client.spread_log(params)
    if result.success
      @spread_log = result.value
    else
      render :json => result
    end
  end
  # ##########################
  #
  # 样本属性相关
  #
  # ##########################
  def attributes
    sample_attr_client = Admin::SampleAttributeClient.new(session_info)
    result = sample_attr_client.index(params)
    if result.success
      @attributes = result.value
    else
      render :json => @attributes
    end
  end

  def add_attributes
    sample_attr_client = Admin::SampleAttributeClient.new(session_info)
    params[:attribute][:type] = params[:attribute][:type].to_i
    if params[:attribute][:id].present?
      sample_attr_client.update_attribute(params[:attribute])
      redirect_to "/admin/samples/#{params[:attribute][:id]}/edit_attributes"
    else
      sample_attr_client.create_attribute(params[:attribute])
      redirect_to "/admin/samples/attributes"
    end
  end

  def new_attributes
    @attribute = {}
  end

  def edit_attributes
    sample_attr_client = Admin::SampleAttributeClient.new(session_info)
    result = sample_attr_client.show(params[:id])
    @attribute = result
  end

  def destroy_attributes
    sample_attr_client = Admin::SampleAttributeClient.new(session_info)
    render :json => sample_attr_client.delete_attribute(params[:id])
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