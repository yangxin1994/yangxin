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