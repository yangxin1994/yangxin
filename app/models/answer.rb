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
	field :template_answer_content, :type => Hash
	field :logic_control_result, :type => Hash
	field :repeat_time, :type => Integer, default: 0
	# reject_type: 0 for rejected by quota, 1 for rejected by quliaty control, 2 for rejected by screen, 3 for timeout
	field :reject_type, :type => Integer
	field :finish_type, :type => Integer
	field :username, :type => String, default: ""
	field :password, :type => String, default: ""

	field :region, :type => String, default: ""
	field :channel, :type => Integer
	field :ip_address, :type => String, default: ""

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
		return ErrorEnum::SURVEY_NOT_EXIST if survey.nil?
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
		return ErrorEnum::SURVEY_NOT_EXIST if survey.nil?
		answer = Answer.new(channel: channel, ip: ip, region: Tool.get_region_by_ip(ip), username: username, password: password)

		# initialize the answer content
		answer_content = {}
		survey.pages.each do |page|
			page["questions"].each do |q_id|
				answer_content["q_id"] = nil
			end
		end
		logic_control = survey.show_logic_control
		logic_control.each do |rule|
			if rule["rule_type"] == 1
				rule["result"].each do |q_id|
					answer_content[q_id] = {}
				end
			end
		end
		answer.answer_content = answer_content

		# initialize the logic control result
		logic_control_result = {}
		logic_control.each do |rule|
			if rule["rule_type"] == 3
				logic_control_result = logic_control_result.merge(rule["result"])
			elsif rule["rule_type"] == 5
				cur_logic_control_rule = {"question_id" => rule["result"]["question_id_2"], "items" => []}
				rule["result"]["items"].each do |input_ids|
					cur_logic_control_rule["items"] << input_ids[1]
				end
				logic_control_result = logic_control_result.merge(cur_logic_control_rule)
			end
		end
		answer.logic_control_result = logic_control_result

		answer.save
		operator.answers << answer
		survey.answers << answer
		return answer
	end

	#*description*: check whether the answer satisfies the channel, ip, and address quota, and set the status
	#
	#*params*:
	#
	#*retval*:
	#* true: when the quotas can be satisfied
	#* false: otherwise
	def check_channel_ip_address_quota
		# 1. get the corresponding survey, quota, and quota stats
		quota = self.survey.quota
		quota_stats = self.survey.quota_stats
		# 2. if all quota rules are satisfied, the new answer should be rejected
		return false if quota_stats["quota_satisfied"]
		# 3 else, if the "is_exclusive" is set as false, the new answer should be accepted
		return true if !quota["is_exclusive"]
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
			return true
		end
		# 5 cannot find a quota rule to accept this new answer
		return false
	end

	#*description*: called by "refresh_quota_stats" in survey.rb, check whether the answer satisfies the given conditions
	#
	#*params*:
	#* conditions: array, the conditions to be checked
	#
	#*retval*:
	#* true: when the conditions can be satisfied
	#* false: otherwise
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
				satisfy = Tool.check_choice_question_answer(self.answer_content[question_id], require_answer)
			when "1"
				question_id = condition["name"]
				require_answer = condition["value"]
				satisfy = Tool.check_choice_question_answer(self.answer_content[question_id], require_answer)
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

	#*description*: called by "check_quota_questions", check whether the answer satisfies question quota conditions in the given conditions
	#
	#*params*:
	#* conditions: array, the conditions to be checked
	#
	#*retval*:
	#* true: when the conditions can be satisfied
	#* false: otherwise
	def satisfy_question_quota_conditions(conditions)
		# check the conditions one by one
		conditions.each do |condition|
			satisfy = false
			case condition["condition_type"].to_s
			when "0"
				volunteer_answer = self.answer_content[condition["name"]]
				require_answer = condition["value"]
				# if the volunteer has not answered this question, cannot reject the volunteer
				satisfy = volunteer_answer.nil? || Tool.check_choice_question_answer(volunteer_answer, require_answer)
			when "1"
				volunteer_answer = self.answer_content[condition["name"]]
				require_answer = condition["value"]
				# if the volunteer has not answered this question, cannot reject the volunteer
				satisfy = volunteer_answer.nil? || Tool.check_choice_question_answer(volunteer_answer, require_answer)
			end
			return satisfy if !satisfy
		end
		return true
	end

	#*description*: clear the answer contents, only work for answers with "redo" status
	#
	#*params*:
	#
	#*retval*:
	#* true: when the answer content is cleared
	#* ErrorEnum::WRONG_ANSWER_STATUS
	def clear
		return ErrorEnum::WRONG_ANSWER_STATUS if !self.is_redo
		self.answer_content = {}
		self.save
		self.set_edit
		return true
	end

	#*description*: finish an answer, only work for answers that allow pageup (those that do not allow pageup finish automatically)
	#
	#*params*:
	#
	#*retval*:
	#* true: when the answer is set as finished
	#* ErrorEnum::WRONG_ANSWER_STATUS
	#* ErrorEnum::SURVEY_NOT_ALLOW_PAGEUP
	#* ErrorEnum::ANSWER_NOT_COMPLELTE
	def finish
		return ErrorEnum::WRONG_ANSWER_STATUS if !self.is_redo
		return ErrorEnum::SURVEY_NOT_ALLOW_PAGEUP if !self.survey.is_pageup_allowed
		self.answer_content.each_value do |value|
			return ErrorEnum::ANSWER_NOT_COMPLETE if value.nil?
		end
		self.set_finish
		return true
	end

	#*description*: check whether the answer expires and update the answer's status
	#
	#*params*:
	#
	#*retval*:
	#* the status of the answer after updating
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

	#*description*: update the answer content
	#
	#*params*:
	#* the type of the answer content, can be 0 (quota template questions' answers) or 1 (normal questions' answers)
	#* the answer to be checked
	#
	#*retval*:
	#* true: when the answers are successfully updated
	def update_answer(answer_type, answer_content)
		answer_to_be_updated = answer_type == 0? self.template_answer_content : self.answer_content
		answer_content.each do |k, v|
			return ErrorEnum::QUESTION_NOT_EXIST if !answer_to_be_updated.has_key?(k)
			answer_to_be_updated[k] = v
		end
		return self.save
	end

	#*description*: check whether the answer content violates the quality control rules
	#
	#*params*:
	#* the answer content to be checked
	#
	#*retval*:
	#* true: when the quality control rules are not violated
	#* false: when the quality control rules are violated
	def check_quality_control(answer_content)
		# find out quality control questions
		quality_control_question_ary = []
		answer_content.each do |k, v|
			question = Question.find_by_id(k)
			quality_control_question_ary << question if !question.nil? && question.question_class == 2
		end
		# if there is no quality control questions, return
		return true if quality_control_question_ary.empty?
		# if there are quality control questions, check whether passing the quality control
		quality_control_question_ary.each do |q|
			quality_control_question_id = q.reference_id
			retval = self.check_quality_control_answer(q._id, quality_control_question_id)
			return false if !retval
		end
		return true
	end

	#*description*: for a specific question answer, check whether the answer violates the quality control rules
	#
	#*params*:
	#* the id of the question the volunteer answers
	#* the id of the quality control question
	#
	#*retval*:
	#* true: when the quality control rules are not violated
	#* false: when the quality control rules are violated
	def check_quality_control_answer(question_id, quality_control_question_id)
		standard_answer = QualityControlQuestionAnswer.find_by_question_id(quality_control_question_id)
		if standard_answer.quality_control_type == 0
			# this is objective quality control question
			volunteer_answer = self.answer_content[question_id]
			case standard_answer.question_type
			when QuestionTypeEnum::CHOICE_QUESTION
				return Tool.check_choice_question_answer(self.answer_content[question_id], 
					standard_answer.answer_content["items"],
					standard_answer.answer_content["fuzzy"])
			when QuestionTypeEnum::TEXT_BLANK_QUESTION
				return Tool.check_choice_question_answer(self.answer_content[question_id], 
					standard_answer.answer_content["text"],
					standard_answer.answer_content["fuzzy"])
			when QuestionTypeEnum::NUMBER_BLANK_QUESTION
				return standard_answer.answer_content["number"] == self.answer_content[question_id]
			else
				return true
			end
		else
			# this is matching quality control question
			# find all the volunteer answers of this group of quality control questions
			matching_question_id_ary = MatchingQuestion.get_matching_question_ids(question_id)
			volunteer_answer = []
			self.answer_content.each do |k,v|
				question = Question.find_by_id(k)
				next if !matching_question_id_ary.include?(question.reference_id)
				v.each do |input_id|
					volunteer_answer << [question.reference_id, input_id]
				end
			end
			standard_matching_items = standard_answer.answer_content["matching_items"]
			standard_matching_items.each do |standard_matching_item|
				volunteer_answer.each do |one_input_answer|
					next if !standard_matching_item.include?(one_input_answer)
				end
				return true
			end
			return false
		end
	end

	#*description*: called when the answer violates the quality control rules
	#
	#*params*:
	#
	#*retval*:
	#* ErrorEnum::VIOLATE_QUALITY_CONTROL_ONCE: when this is the first time
	#* ErrorEnum::VIOLATE_QUALITY_CONTROL_TWICE: when this is the second time
	def violate_quality_control
		self.repeat_time = self.repeat_time + 1 if self.repeat_time < 2
		self.save
		if self.repeat_time == 1
			self.set_redo
			return ErrorEnum::VIOLATE_QUALITY_CONTROL_ONCE
		else
			self.set_reject
			self.update_attributes(reject_type: 1)
			return ErrorEnum::VIOLATE_QUALITY_CONTROL_TWICE
		end
	end

	#*description*: check whether the volunteer passes the screen questions
	#
	#*params*:
	#* the answer content to be checked
	#
	#*retval*:
	#* true
	#* false
	def check_screen(answer_content)
		logic_control = self.survey.show_logic_control
		question_id_ary = answer_content.values
		logic_control.each do |logic_control_rule|
			# only check the screen logic control rules
			next if logic_control_rule["rule_type"] != 0
			screen_condition_question_id_ary = logic_control_rule["conditions"].map {|ele| ele["question_id"]}
			# check whether, in the answers submitted, there are screen questions for this logic control rule
			target_question_id_ary = question_id_ary & screen_condition_question_id_ary
			next if target_question_id_ary.empty?

			# for each condition, check whether it is violated
			logic_control_rule["conditions"].each do |condition|
				# if the volunteer has not answered this question, stop the checking of this rule
				break if answer_content[condition["question_id"]].nil?
				pass_condition = Tool.check_choice_question_answer(answer_content[condition["question_id"]], condition["answer"], condition["fuzzy"])
				return ErrorEnum::VIOLATE_SCREEN if !pass_condition
			end
		end
		return true
	end

	#*description*: called when the answer violates the screen rules
	#
	#*params*:
	#
	#*retval*:
	#* ErrorEnum::VIOLATE_SCREEN
	def violate_screen
		self.set_reject
		self.update_attributes(reject_type: 2)
		return ErrorEnum::VIOLATE_SCREEN
	end

	#*description*: check whether the volunteer passes the quotas of questions
	#
	#*params*:
	#
	#*retval*:
	#* true
	#* false
	def check_quota_questions
		# 1. get the corresponding survey, quota, and quota stats
		quota = self.survey.show_quota
		quota_stats = self.survey.quota_stats
		# 2. if all quota rules are satisfied, the new answer should be rejected
		return false if quota_stats["quota_satisfied"]
		# 3 else, if the "is_exclusive" is set as false, the new answer should be accepted
		return true if !quota["is_exclusive"]
		# 4. check the rules one by one
		quota["rules"].each_with_index do |rule, rule_index|
			# find out a rule that:
			# a. the quota of the rule has not been satisfied
			# b. this answer satisfies the rule
			return true if quota_stats["answer_number"][rule_index] < rule["amount"] && self.satisfy_question_quota_conditions(rule["conditions"])
		end
		return false
	end

	#*description*: called when the answer violates the screen rules
	#
	#*params*:
	#
	#*retval*:
	#* ErrorEnum::VIOLATE_QUOTA
	def violate_quota
		self.set_reject
		self.update_attributes(reject_type: 0)
		return ErrorEnum::VIOLATE_QUOTA
	end

	def update_logic_control_result(answer_type, answer_content)
		# only normal questions are related to logic control
		return if answer_type == 0
		logic_control = self.survey.show_logic_control
		
	end

	def auto_finish
		
	end
end
