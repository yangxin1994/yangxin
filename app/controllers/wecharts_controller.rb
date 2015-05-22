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
		#Rails.logger.info "--------------openid:#{openid}"
		
		#Rails.logger.info "--------------order:#{order.try(:id).to_s}"
		answer    = Answer.where(id:params[:state]).first
		if answer
			sid   = answer.survey.id.to_s
			sids  = Order.where(type:Order::HONGBAO,open_id:openid).map{|order| order.answer.survey.id.to_s}.uniq
			unless sids.include?(sid)
				#未领红包	
				order  = Order.create_hongbao_order(params[:state],openid)
			else
				#已领红包
				Rails.logger.info '============================'
				Rails.logger.info '您已经领取过红包╮(╯▽╰)╭'
				Rails.logger.info '============================'					
			end
		else
			Rails.logger.info '------系统错误,没有找到对应的answer----'
		end
		
		Rails.logger.info "answer: #{answer.id.to_s}"
		unless order.present?
			order  = Order.create_hongbao_order(params[:state],openid)
			Rails.logger.info "new_order:#{order.id.to_s}"
			total_amount = answer.reward_scheme.wechart_reward_amount.to_s
			amount_arr   = total_amount.scan(/\d+/)
			if amount_arr.length == 1
				#设置了每份问卷奖励多少
				total_amount = amount_arr.first.to_i
				min_value    = total_amount
				max_value    = total_amount
			elsif amount_arr.length == 2
				#设置了每份问卷奖励的金额范围,具体金额由微信随机分配
				value        = rand(amount_arr.first.to_i..amount_arr.last.to_i)
				min_value    = max_value = total_amount = value
			end
			res = Wechart.send_red_pack(order.code,openid,request.remote_ip,total_amount,min_value,max_value)
			if res
				Rails.logger.info "send_red_pack ok ---------"
				order.update_attributes(amount:total_amount,status:Order::SUCCESS)
			else
				Rails.logger.info "send_red_pack fail ---------"
				order.destroy
			end
		else
			Rails.logger.info '============================'
			Rails.logger.info '您已经领取过红包╮(╯▽╰)╭'
			Rails.logger.info '============================'
		end
		
		wuser  = WechartUser.where(openid:openid).first
		unless wuser.present?
			WechartWorker.perform_async('create',{open_id:openid}) 
		end
		
		redirect_to "/s/#{answer.survey.wechart_scheme_id}"
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


