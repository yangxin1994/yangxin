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
    quota_setting.quota["gender"] = params[:gender].values.map! { |e| e.to_i }
    quota_setting.quota["age"] = params[:age].values.map! { |e| e.to_i }
    quota_setting.quota["income"] = params[:income].values.map! { |e| e.to_i }
    quota_setting.quota["education"] = params[:education].values.map! { |e| e.to_i }
    params[:region].each do |k,v|
	    quota_setting.quota["region"][k] = v.to_i
		end
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

  def recharge_fail_mobile
    CarnivalOrder.recharge_fail_mobile
    redirect_to action: :orders and return
  end

  def check_order_result
    order = CarnivalOrder.find(params[:carnival_order_id])
    retval = order.check_result
    logger.info "AAAAAAAAAAAAAAAA"
    logger.info retval
    logger.info "AAAAAAAAAAAAAAAA"
    render_json_auto retval
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
end
