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

	def get_red_pack
		openid    = cookies[:od]
		awid      = cookies[:awd]
		if openid && awid
			answer    = Answer.where(:id => awid,:open_id => openid,:status => Answer::FINISH).first
			survey    = answer.survey
			if survey.open_red_pack
				if answer
					sid   = answer.survey.id.to_s
					sids  = Order.where(type:Order::HONGBAO,open_id:openid).map{|order| order.answer.survey.id.to_s}
					unless sids.include?(sid)
						#未领红包	
						order  = Order.where(answer_id:awid,survey_id:answer.survey.id.to_s).first
						if order.present?
							render_json_e('您已经领取过红包')	and return 
						end
						order  = Order.create_hongbao_order(awid,openid)
						total_amount = answer.reward_scheme.wechart_reward_amount.to_s
						amount_arr   = total_amount.scan(/\d+/)
						if amount_arr.length == 1
							#设置了每份问卷奖励多少
							min_value    = max_value  = total_amount = amount_arr.first.to_i
						elsif amount_arr.length == 2
							#设置了每份问卷奖励的金额范围,具体金额由微信随机分配
							value        = rand(amount_arr.first.to_i..amount_arr.last.to_i)
							min_value    = max_value = total_amount = value
						end
						res = Wechart.send_red_pack(order.code,openid,request.remote_ip,total_amount,min_value,max_value)
						if res
							order.update_attributes(amount:total_amount,status:Order::SUCCESS)
							cookies.delete(:od, :domain => :all)
							cookies.delete(:awd, :domain => :all)
							render_json_s(true) and return 
						else
							order.destroy
							render_json_e('系统错误') and return 
						end
					else
						#已领红包
						render_json_e('您已经领取过红包')	and return 				
					end
				else
					render_json_e('答案不存在') and return 
				end			
			else
				render_json_e('该问卷已关闭红包领取') and return 
			end
		else
			render_json_e('非微信用户错误') and return 		
		end
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


