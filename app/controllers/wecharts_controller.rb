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
		order  = Order.where(open_id:openid,answer_id:params[:state]).first
		answer = Answer.find(params[:state])
		# redirect_to a special page and show that has already get the hongbao
		unless order.present?
			order  = Order.create_hongbao_order(params[:state],openid)
			total_amount = answer.reward_scheme.wechart_reward_amount.to_s
			amount_arr   = total_amount.scan(/\d+/)
			if amount_arr.length == 1
				#设置了每份问卷奖励多少
				total_amount = amount_arr.first.to_i
				min_value    = total_amount
				max_value    = total_amount
			elsif amount_arr.length == 2
				#设置了每份问卷奖励的金额范围,具体金额由微信随机分配
				min_value    = amount_arr.first.to_i
				max_value    = amount_arr.last.to_i
				total_amount = rand(min_value..max_value)
			end
			Rails.logger.info '************************************'
			Rails.logger.info "order_code:#{order.code}"
			Rails.logger.info "openid:#{openid}"
			Rails.logger.info "ip:#{request.remote_ip}"
			Rails.logger.info "total_amount:#{total_amount}"
			Rails.logger.info "min_value:#{min_value}"
			Rails.logger.info "max_value:#{max_value}"
			Rails.logger.info '************************************'
			res = Wechart.send_red_pack(order.code,openid,request.remote_ip,total_amount,min_value,max_value)
			if res
				#order.update_attributes(amount:total_amount)
			end
		else
			Rails.logger.info '============================'
			Rails.logger.info '您已经领取过红包╮(╯▽╰)╭'
			Rails.logger.info '============================'
		end
		
		wuser  = WechartUser.where(openid:openid).first
		unless wuser.present?
			WechartWorker.perform_async('get_user_info',{open_id:openid}) 
		end
		

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


