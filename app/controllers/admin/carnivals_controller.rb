# encoding: utf-8
class Admin::CarnivalsController < Admin::AdminController

  layout "layouts/admin-todc"

  def pre_surveys
    @quota_setting = Carnival.where(survey_id: Carnival::PRE_SURVEY, type: Carnival::SETTING).first
    @quota_stats = Carnival.where(survey_id: Carnival::PRE_SURVEY, type: Carnival::STATS).first
  end

  # update quota of pre surveys
  def update_quota
    # render text: "hello" and return
    quota_setting = Carnival.where(survey_id: Carnival::PRE_SURVEY, type: Carnival::SETTING).first
    quota_setting.quota[:gender] = params[:gender].values
    quota_setting.quota[:age] = params[:age].values
    quota_setting.quota[:income] = params[:income].values
    quota_setting.quota[:education] = params[:education].values
    quota_setting.quota[:region] = params[:region]
    quota_setting.save
    redirect_to action: :pre_surveys and return
  end

  def surveys
    @quotas = Carnival.where(type: Carnival::STATS).in(survey_id: Carnival::SURVEY)
  end

  def region_quota
    @quota = Carnival.where(survey_id: params[:survey_id]).first
  end

  def orders
    @orders = CarnivalOrder.all
  end
end
