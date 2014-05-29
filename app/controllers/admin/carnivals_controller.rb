# encoding: utf-8
class Admin::CarnivalsController < Admin::AdminController

  layout "layouts/admin-todc"

  def pre_surveys
    @quota_setting = Carnival.where(survey_id: Carnival::PRE_SURVEY, type: Carnival::SETTING).first
    @quota_stats = Carnival.where(survey_id: Carnival::PRE_SURVEY, type: Carnival::STATS).first
  end

  # update quota of pre surveys
  def update_quota
    
  end

  def surveys
    @quotas = Carnival.where(type: Carnival::STATS).all(survey_id: Carnival::SURVEY)
  end

  def region_quota
    @quota = Carnival.where(survey_id: params[:survey_id])
  end

  def orders
    @orders = CarnivalOrder.all
  end
end
