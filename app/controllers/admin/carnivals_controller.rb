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
    params.each{|k, v| params.delete(k) unless v.present?}
    if params[:keyword]
      if params[:keyword].length == 13
        params[:code] = params[:keyword]
      else
        params[:mobile] = params[:keyword]
      end
      params.delete :keyword
    end
    order_list = CarnivalOrder.search_orders(params)
    @orders = auto_paginate(order_list)   
  end

  def handle
    render_json CarnivalOrder.where(:_id => params[:id]).first do |order|
      order.manu_handle
    end
  end
  def finish
    render_json CarnivalOrder.where(:_id => params[:id]).first do |order|
      order.finish(params[:success] == 'true', params[:remark])
    end
  end
  def update_express_info
    render_json CarnivalOrder.where(:_id => params[:id]).first do |order|
      order.update_express_info(params[:express_info])
    end
  end
  def update_remark
    render_json CarnivalOrder.where(:_id => params[:id]).first do |order|
      order.update_remark(params[:remark]) 
    end
  end
    
end
