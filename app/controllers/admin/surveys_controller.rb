# encoding: utf-8
# already tidied up

class Admin::SurveysController < Admin::AdminController

  layout "layouts/admin-todc"

	# *****************************

  def index
    @side_nav = [
      {url:"asdf", title:"asdf"}
    ]
    @surveys = auto_paginate Survey.search(params)
  end

  def star
    render_json Survey.where(:_id => params[:id]).first do |survey|
      survey.star = !(params[:star].to_s == 'true')
      survey.save
      survey.star
    end
  end

  def more_info
    render_json Survey.where(:_id => params[:id]).first do |survey|
      {
        :hot => survey.quillme_hot,
        :spread => survey.spread_point,
        :visible => survey.publish_result,
        :max_num_per_ip => survey.max_num_per_ip
      }
    end
  end

  def promote_info
    render_json Survey.where(:_id => params[:id]).first do |survey|
      {
        :email => survey.email_promote_info,
        :sms => survey.sms_promote_info
      }
    end
  end

  def cost_info
    render_json Survey.where(:_id => params[:id]).first do |survey|
      survey.cost_info
    end
  end

  def set_info
    render_json Survey.where(:_id => params[:id]).first do |survey|
      @is_succuess = 
        survey.set_quillme_hot(params[:hot].to_s == "true") &&
        survey.set_spread(params[:spread].to_i) &&
        survey.update_attributes({'publish_result' => (params[:visible].to_s == "true"),
                                  'max_num_per_ip' => params[:max_num_per_ip].to_i})
      {
        :hot => survey.quillme_hot,
        :spread => survey.spread_point,
        :visible => survey.publish_result,
        :max_num_per_ip => survey.max_num_per_ip
      }
    end
  end

  def reward_schemes
    survey = Survey.where(:_id => params[:id]).first
    @reward_schemes = survey.reward_schemes.not_default
    @prizes = Prize.all
    if @editing_rs = RewardScheme.where(:id => params[:editing]).first
      @editing_rs["rewards"].each do |reward|
        case reward["type"].to_i
        when 1
          @editing_rs["tel_charge"] = reward["amount"]
        when 2
          @editing_rs["alipay"] = reward["amount"]
        when 4
          @editing_rs["point"] = reward["amount"]
        when 8
          @editing_rs["prizes"] = reward["prizes"]
        when 16
          @editing_rs["jifenbao"] = reward["amount"]
        else

        end
      end
      if @editing_rs["rewards"].present?
        @editing_rs['is_free'] = "no" 
      else
        @editing_rs['is_free'] = "yes" 
      end
    else
      @editing_rs ={}
    end    
  end  

  def show
    _r = Survey.find(params[:id]).info_for_admin
    @survey = _r["survey"]
    @questions = {}
    _r['questions'].each do |question_id, question|
      @survey["logic_control"].each do |lc|
        lc["conditions"].each do |condition|
          if condition["question_id"] == question_id
            question["is_logic_control"] = true
            # question["logic_control_type"] = lc["rule_type"]
            question["issue"]["items"] = question["issue"]["items"].try('map') do |item|
              if condition["answer"].include? item["id"]
                item["is_fuzzy"] = condition["fuzzy"]
                item["is_logic_control"] = true
                item["logic_control_type"] = lc["rule_type"]
              end
              item
            end
          end
        end
      end
      @questions[question_id] = question
    end    
  end

  # 推送渠道设置相关

  def sample_attributes
    render_json Survey.where(:_id => params[:id]).first do |survey|
      surveys_smp_attrs = survey.sample_attributes_for_promote.map { |e| e["sample_attribute_id"] }
      SampleAttribute.normal.order_by(:type => :asc).map do |smp_attr|
        smp_attr unless surveys_smp_attrs.include? smp_attr._id
      end
    end    
  end

  def update_sample_attribute
    
  end

  def promote
    if survey = Survey.where(:_id => params[:id]).first
      @promote = survey.serialize_in_promote_setting
      gon.push({:id => params[:id]})
    else

    end
  end

  def update_promote
    survey = Survey.find params[:id]
    if @promote = survey.update_promote(params)
      survey.update_quillme_promote_reward_type
      redirect_to "/admin/surveys/#{params[:id]}/promote",:flash => {:success => "推送渠道设置成功"}
    else
      flash.alert = "发生错误!请检查输入数据!"
    end
  end

  def destroy_attributes
    render_json Survey.where(:_id => params[:id]).first do |survey|
      survey.sample_attributes_for_promote.delete_at(params[:sample_attribute_index].to_i)
      survey.save
    end    
  end

# ###########################
#
# 问题属性绑定
#
# ###########################

  def bind_question
    if request.get?
      _bind_question
    elsif request.put?
      _update_bind
    elsif request.delete?
      _unbind_question
    end
  end

  private

  def _bind_question

    @question = Question.find_by_id(params[:id])
    @attrs = SampleAttribute.all
    case @question['question_type']
    when 0 # choice
      if @question['issue']['max_choice'] == 1
        @attrs = @attrs.select {|attr| attr['type'] != 7} # except array
      else
        @attrs = @attrs.select {|attr| attr['type'] == 7} # only array
      end
    when 2 # text_blank
      @attrs = @attrs.select {|attr| attr['type'] == 0}
    when 3 # number_blank
      @attrs = @attrs.select {|attr| [2, 4].include? attr['type']}
    when 7 # time_blank
      @attrs = @attrs.select {|attr| [3, 5].include? attr['type']}
    when 8 # addr
      @attrs = @attrs.select {|attr| attr['type'] == 6}
    end
    @addr_precision = 0
    if @question['sample_attribute_id']
      @attr = @attrs.select {|attr| attr['_id'] == @question['sample_attribute_id']}[0]
      if @attr['type'] == 6
        @question['sample_attribute_relation'].each do |key, value|
          addr = QuillCommon::AddressUtility.find_province_city_town_by_code(value)
          next if addr.blank?
          @addr_precision = addr.split(/\s+\-\s+/).length - 1
          break
        end
      end
    end
  end

  def _unbind_question
    @question = Question.find_by_id(params[:id])
    @question.remove_sample_attribute
    redirect_to :back
  end

  def _update_bind
    params[:relation] = JSON.parse params[:relation]
    @question = Question.find params[:id]
    @question.sample_attribute_relation = params[:relation]
    @question.sample_attribute_id = params[:attribute_id]
    @question.save
    render json: {}
  end
  
end

