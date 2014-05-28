# encoding: utf-8
class Admin::CarnivalsController < Admin::AdminController

  layout "layouts/admin-todc"

  def pre_surveys
    @quota = Carnival.where(survey_id: Carnival::PRE_SURVEY, type: Carnival::SETTING)
  end

  def surveys
    @quotas = Carnival.where(type: Carnival::STATS).all(survey_id: Carnival::SURVEY)
  end

  def orders
    
  end
end
