# encoding: utf-8
require 'error_enum'
require 'publish_status'
require 'securerandom'
require 'tool'
class Answer
	include Mongoid::Document
	include Mongoid::Timestamps
	# status: 0 for editting, 1 for reject, 2 for finish, 3 for redo
	field :status, :type => Integer, default: 0
	field :answer_content, :type => Hash
	field :repeat_time, :type => Integer, default: 0
	# reject_type: 0 for rejected by quota, 1 for rejected by quliaty control, 2 for rejected by screen, 3 for timeout
	field :reject_type, :type => Integer
	field :finish_type, :type => Integer
	field :username, :type => String, default: ""
	field :password, :type => String, default: ""

	field :region, :type => String, default: ""
	field :channel, :type => Integer
	field :ip_address, :type => Integer

	belongs_to :user
	belongs_to :survey

	STATUS_NAME_ARY = ["edit", "reject", "finish", "redo"]

	def self.def_status_attr
		STATUS_NAME_ARY.each_with_index do |status_name, index|
			define_method("is_#{status_name}".to_sym) { return index == self.status }
			define_method("set_#{status_name}".to_sym) { self.status = index; self.save}
		end
	end
	def_status_attr

	public

	def self.find_by_id(answer_id)
		answer = Answer.where(:id => answer_id).first
		return answer
	end

	def self.find_by_survey_id_and_user(survey_id, user)
		survey = Survey.find_by_id(survey_id)
		return ErroEnum::SURVEY_NOT_EXIST if survey.nil?
		answers = survey.answers
		answers.each do |answer|
			if answer.user == user
				return answer
			end
		end
		return nil
	end

	def self.find_by_password(username, password)
		answer = Answer.where(username: username, password: password)
		return answer
	end

	def self.create_answer(operator, survey_id, channel, ip, username, password)
		survey = Survey.find_by_id(survey_id)
		return ErroEnum::SURVEY_NOT_EXIST if survey.nil?
		answer = Answer.new(channel: channel, ip: ip, region: Tool.get_region_by_ip(ip), username: username, password: password)
		answer.save
		operator.answers << answer
		survey.answers << answer
		return answer
	end

	def check_channel_ip_address_quota
		# 1. get the corresponding survey, quota, and quota stats
		quota = self.survey.quota
		quota_stats = self.survey.quota_stats
		# 2. if all quota rules are satisfied, the new answer should be rejected
		if quota_stats["quota_satisfied"]
			self.set_reject
			self.update_attributes(reject_type: 0)
			return false
		end
		# 3 else, if the "is_exclusive" is set as false, the new answer should be accepted
		if quota["is_exclusive"] == false
			self.set_edit
			return true
		end
		# 4 the rules should be checked one by one to see whether this answer can be satisfied
		quota = self.survey.quota
		quota_stats = self.survey.quota_stats
		quota["rules"].each_with_index do |rule, index|
			# move to next rule if the quota of this rule is already satisfied
			next if quota_stats["answer_number"][index] >= rule["amount"]
			rule["conditions"].each do |condition|
				# if the answer's ip, channel, or region violates one condition of the rule, move to the next rule
				next if condition["condition_type"] == 2 && region != condition["value"]
				next if condition["condition_type"] == 3 && channel != condition["value"]
				next if condition["condition_type"] == 4 && Tool.check_ip_mask(ip, condition["value"])
			end
			# find out one rule. the quota for this rule has not been satisfied, and the answer does not violate conditions of the rule
			self.set_edit
			return true
		end
		# 5 cannot find a quota rule to accept this new answer
		self.set_reject
		self.update_attributes(reject_type: 0)
		return false
	end

	def satisfy_quota_conditions(conditions)
		# only answers that are finished contribute to quotas
		return false if !self.is_finish
		# check the conditions one by one
		conditions.each do |condition|
			satisfy = false
			case condition["condition_type"].to_s
			when "0"
				question_id = condition["name"]
				require_answer = condition["value"]
				satisfy = Tool.check_question_answer(self.answer_content[question_id], require_answer)
			when "1"
				question_id = condition["name"]
				require_answer = condition["value"]
				satisfy = Tool.check_question_answer(self.answer_content[question_id], require_answer)
			when "2"
				satisfy = condition["value"] == answer["region"]
			when "3"
				satisfy = condition["value"] == answer["channel"].to_s
			when "4"
				satisfy = Tool.check_ip_mask(condition["value"], answer["ip_address"])
			end
			return satisfy if !satisfy
		end
		return true
	end

	def update_status
		if Time.now.to_i - self.created_at.to_i > EXPIRATION_TIME
			self.set_reject
			self.update_attributes(reject_type: 3)
		end
		return self.status
	end

	def delete
		# only answers that are finished can be deleted
	end

	def update_answer(answer_obj)
		# 1. update the answer
		self.answer_content = answer_obj["answer_content"]
		self.save

		# 2. check whether the user passes the quota checking
		# 3. check whether the user is screened out 
		# 4. check whether the user fails to pass the quality control
	end
end
