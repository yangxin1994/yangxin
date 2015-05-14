# encoding: utf-8
require 'digest/sha1'
class WechartsController < ApplicationController
    def wechart_api
    	if request.get?
    		Rails.logger.info '=========================='
    		Rails.logger.info 'wechart_api get 请求。。。。。。'
    		Rails.logger.info '=========================='
    	else
    		Rails.logger.info '=========================='
    		Rails.logger.info 'wechart_api post 请求。。。。。。'
    		Rails.logger.info '=========================='
    		# do other things 
    	end
    	result = verify
    	render :text => params[:echostr] and return if result
    	render :text => 'false'
    end

	def wechart_auth
		openid = Wechart.get_open_id(params[:code])
		order  = Order.where(open_id:openid,answer_id:params[:state])
		# redirect_to a special page and show that has already get the hongbao
		order  = Order.create_hongbao_order(params[:state],openid) unless order.present?
		wuser  = WechartUser.where(openid:openid).first
		WechartWorker.perform_async('get_user_info',{open_id:openid}) unless wuser.present?
		render :text => 'false'
	end

	def verify
		token     =  Wechart.token
		tmp_arr   =  []
		tmp_arr   << token
		tmp_arr   << params[:timestamp]
		tmp_arr   << params[:nonce]
		tmp_arr.sort!
		tmp_arr.join
		str       =  Digest::SHA1.hexdigest(tmp_arr.join)
		return true if str == params[:signature]
		return false 	
	end

end


