# encoding: utf-8

class Admin::SurveysController < Admin::AdminController

  layout "layouts/admin-todc"

	# *****************************

  def index
    @surveys = auto_paginate Survey.search(params) do |surs|
      surs.map do |sur|
        sur.append_user_fields([:email, :mobile])
        sur.serialize_for([:title, :email, :mobile, :created_at])
        sur
      end
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
    # @survey = Survey.where(:_id => params[:id])
    # result = @client.show(params)
    # if result[:success] || result.try(:success)
    #   @questions = result[:questions]
    #   @survey = result[:survey]
    # else
    #   render :json => result
    # end
  end



  def promote
    if survey = Survey.where(:_id => params[:id]).first
      @promote = survey.get_all_promote_settings
    else

    end
  end

  def update_promote
    survey = Survey.find params[:id]
    if @promote = survey.update_promote(params)
      redirect_to "/admin/surveys/#{params[:id]}/promote",:flash => {:success => "推送渠道设置成功"}
    else
      flash.alert = "发生错误!请检查输入数据!"
    end
  end

  def destroy_attributes
   result = @client.destroy_attributes(params)
   render :json => result
  end
end