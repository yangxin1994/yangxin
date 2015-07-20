class Filler::SurveysController < Filler::FillerController
    # PAGE
    def show
    	reward_scheme = RewardScheme.find_by_id(reward_scheme_id)
    	render_404 if reward_scheme.nil?
    	survey_id = reward_scheme.survey_id
    	survey    = Survey.find(survey_id)
    	render_404 if survey.nil?

    	if survey.wechart_promotable && cookies[:oid].blank?
    		code  = params[:code]
    		if code.nil?
    		  redirect_to Wechart.snsapi_base_redirect(request.url,request.url)
    		else
    			begin
    			  openid = Wechart.get_open_id(code)
      			  cookies[:oid] = {
      			    :value => openid,
      			    :expires => Rails.application.config.permanent_signed_in_months.months.from_now,
      			    :domain => :all
      			  } 
      			  WechartUser.add_new_user({open_id:openid}) # 如果是红包问卷则先获取用户openid并创建微信用户记录
    			  load_survey(params[:id])
    			rescue Exception => e
    			    render_500
    			end
    		end
    	else
    		load_survey(params[:id])
    	end
    end
end