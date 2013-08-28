# encoding: utf-8
require 'quill_common'
class LotteryLog < Log
	field :type, :type => Integer,:default => 2
	field :result, :type => Boolean, :default => false #表示是否抽中
	field :order_id, :type => String
	field :prize_id, :type => String
	field :prize_name, :type => String
	field :survey_id, :type => String
	field :answer_id, :type => String
	field :survey_title, :type => String
	field :land, :type => String #归属地


	def self.find_lottery_logs(answer_id,status,limit)
		status = nil unless status.present?
		answer = Answer.find_by_id(answer_id)
		survey_id = answer.survey.id
		data = []
		log_data = {}
		if status
			logs = self.where(:survey_id => survey_id,:result => status).desc(:created).limit(limit)
		else
			logs = self.where(:survey_id => survey_id).desc(:created).limit(limit)
		end
		logs.each_with_index do |log,index|
			pri = Prize.find_by_id(log.prize_id)
			log_data['nickname'] = log.user.try(:nickname) || '游客'
			log_data['created_at'] = log.created_at
			log_data['avatar']  = log.user.present? ? (log.user.avatar.present? ? log.user.avatar.picture_url : User::DEFAULT_IMG) : User::DEFAULT_IMG
			log_data['prize_name'] = log.prize_name
			log_data['price'] = pri.try(:price)
			log_data['land'] = log.land || '未知城市' 
			log_data['photo_src'] = pri.photo.present? ? pri.photo.picture_url : Prize::DEFAULT_IMG  if pri.present?
			data[index] = log_data
			log_data = {}
		end
		return data
	end

	def info_for_admin
		lottery_log_obj = {}
		lottery_log_obj["created_at"] = self.created_at.to_i
		lottery_log_obj["result"] = self.result.to_s
		lottery_log_obj["order_id"] = self.order_id
		lottery_log_obj["prize_name"] = self.prize_name
		return lottery_log_obj
	end

	def self.create_fail_lottery_log(answer_id,survey_id,survey_title,user_id,ip_address)
		address_code = QuillCommon::AddressUtility.find_address_code_by_ip(ip_address)
		land = QuillCommon::AddressUtility.find_province_city_town_by_code(address_code)
		self.create(:answer_id => answer_id,:survey_id =>survey_id,:survey_title => survey_title,:user_id => user_id,:land => land)
	end

	def self.create_succ_lottery_Log(answer_id,order_id,survey_id,user_id,ip_address,prize_id)
		prize_name 	= Prize.find_by_id(prize_id).try(:title)
		survey_title = Survey.find_by_id(survey_id).try(:title)
		address_code = QuillCommon::AddressUtility.find_address_code_by_ip(ip_address)
		land = QuillCommon::AddressUtility.find_province_city_town_by_code(address_code)		
		self.create(:answer_id => answer_id,:order_id => order_id,:prize_id => prize_id,:prize_name => prize_name,:survey_id =>survey_id,:survey_title => survey_title,:user_id => user_id,:land => land,:result => true)
	end

	def self.get_lottery_counts(survey_id)
		total_count = self.where(:survey_id => survey_id).count
		succ_count  = self.where(:survey_id => survey_id,:result => true).count
		return {'total' => total_count,'succ' => succ_count}
	end

	def self.get_order_by_answer_sample(answer_id)
		order = self.where(:answer_id => answer_id).first
	end
end


