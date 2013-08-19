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
        :visible => survey.publish_result
      }
    end
  end

  def set_info
    render_json Survey.where(:_id => params[:id]).first do |survey|
      @is_succuess = 
        survey.set_quillme_hot(params[:hot].to_s == "true") &&
        survey.set_spread(params[:spread].to_i) &&
        survey.update_attributes({'publish_result' => (params[:visible].to_s == "true")})
      {
        :hot => survey.quillme_hot,
        :spread => survey.spread_point,
        :visible => survey.publish_result
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
    @survey = Survey.where(:_id => params[:id])
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
    survey = Survey.where(:_id => params[:id])
    reward_schemes = RewardScheme.where(:survey_id => survey._id)
    result = @client.promote(params)
    if result.success
      @promote = result.value
    else
      render :json => result
    end
  end

  def update_promote
    result = @client.update_promote(params)
    if result.success
      @promote = result.value
      redirect_to "/admin/surveys/#{params[:id]}/promote"
    else
      render :json => result
    end
  end

  def destroy_attributes
   result = @client.destroy_attributes(params)
   render :json => result
  end

end