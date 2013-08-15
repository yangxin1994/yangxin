class Admin::SurveysController < Admin::AdminController

	before_filter :get_client

  layout "layouts/admin-todc"

	def get_client
		@client = Admin::SurveyClient.new(session_info)
	end

	# *****************************

  def index
    result = @client.index(params)
    if result.success
      @surveys = result.value
    else
      render :json => result
    end 
  end

  def more_info
    render :json => @client.more_info(params)
  end

  def set_info
    render :json => @client.set_info(params)
  end

  def show
    result = @client.show(params)
    if result[:success] || result.try(:success)
      @questions = result[:questions]
      @survey = result[:survey]
    else
      render :json => result
    end
  end

  def reward_schemes
    result = @client.reward_schemes(params)
    _prize_result = Admin::PrizeClient.new(session_info)._get({:per_page => 100},'')
    if result.success && _prize_result.success
      @reward_schemes = result.value
      @prizes = _prize_result.value
      @editing_rs = @reward_schemes['editing_rs']
      (@editing_rs['prizes'] || []).each_with_index do |prize, index|
        prize['deadline'] = Time.at(prize['deadline']).strftime("%Y/%m/%d")
        @editing_rs['prizes'][index] = prize
      end
      gon.push @reward_schemes
    else
      render result
    end
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