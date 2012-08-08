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
	# Due to the logic control rules, volunteer's answer will hide/show some questions/choices.
	# The hide/show of questions can be recorded in the "answer_content" field
	# => For those questions that are hidden, their answers are set as "{}", and they will not be loaded
	# The hide/show of choices is recorded in he logic_control_result
	# => Specifically, logic_control_result is used to record those choices that are hidden.
	# => logic_control_result is a hash, the key of which is question id, and the value of which has the following strucutre
	# => => items : array of input ids that are hidden
	# => => sub_questions : array of row ids that are hidden
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
			answer_content = answer_content.merge(Hash[page["questions"].map { |ele| [ele, nil] }])
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
		# initialize the template answer content
		answer.template_answer_content = Hash[survey.quota_template_question_page.map { |ele| [ele, nil] }]

		answer.save
		operator.answers << answer
		survey.answers << answer

		# initialize the logic control result
		logic_control_result = {}
		logic_control.each do |rule|
			if rule["rule_type"] == 3
				rule["result"].each do |ele|
					answer.add_logic_control_result(ele["question_id"], ele["items"], ele["sub_questions"])
				end
			elsif rule["rule_type"] == 5
				items_to_be_added = []
				rule["result"]["items"].each do |input_ids|
					items_to_be_added << input_ids[1]
				end
				answer.add_logic_control_result(rule["result"]["question_id_2"], items_to_be_added, [])
			end
		end
		return answer
	end

	#*description*: load questions for volunteers
	#
	#*params*:
	#* question_id: the id of the question that indicates the location (only works for the surveys that allow pageup)
	#* prev_page: whether show the previous page or the next page (only works for the surveys that allow pageup)
	#
	#*retval*:
	#* array of questions objects
	def load_question(question_id, next_page)
		loaded_question_ids = []
		if self.survey.is_pageup_allowed
			self.survey.pages.each_with_index do |page, page_index|
				next if !page["questions"].include?(question_id)
				question_index = page["questions"].index(question_id)
				if next_page
					# require next page of questions
					if question_index + 1 == page["questions"].length
						return ErrorEnum::PAGE_OVERFLOW if page_index + 1 == self.survey.pages.length
						return load_question_by_ids(self.survey.pages[page_index + 1]["questions"])
					else
						return load_question_by_ids(page["questions"][question_index + 1..-1])
					end
				else
					# require previous page of questions
					if question_index == 0
						return ErrorEnum::PAGE_OVERFLOW if page_index == 0
						return load_question_by_ids(self.survey.pages[page_index - 1]["questions"])
					else
						return load_question_by_ids(page["questions"][0..question_index - 1])
					end
				end
			end
			return ErrorEnum::QUESTION_NOT_EXIST
		else
			# first check whether template questions for attributes quotas are loaded
			template_answer_content_loaded = self.template_answer_content.select { |k,v| v.nil?}
			template_answer_content_loaded.each do |k,v|
				loaded_question_ids << k
			end
			return load_question_by_ids(loaded_question_ids) if !loaded_question_ids.empty?
			# then try to load normal questions
			# summarize the questions that are results of logic control rules
			logic_control_question_id = []
			self.survey.logic_control_rule.each do |rule|
				result_q_ids = rule["result"] if ["1", "2"].include?(rule["type"])
				result_q_ids = rule["result"].map { |e| e["question_id"] } if ["3", "4"].include?(rule["type"])
				result_q_ids = rule["result"]["question_id_2"].to_a if ["5", "6"].include?(rule["type"])
				condition_q_ids = rule["conditions"].map {|condition| condition["question_id"]}
				logic_control_question_id << { "condition" => condition_question_id_ary, "result" => result_q_ids }
			end
			cur_page = false
			self.survey.pages.each do |page|
				page["questions"].each do |q_id|
					next if !self.answer_content[q_id].nil?
					# find out the first question whose answer is nil
					cur_page = true
					# check if this question is the result of some logic control rule
					logic_control_question_id.each do |ele|
						if (ele["condition"] & loaded_question_ids).empty? || !ele["result"].include?(q_id)
							loaded_question_ids << q_id
						else
							return load_question_by_ids(loaded_question_ids)
						end
					end
				end
				return load_question_by_ids(loaded_question_ids) if cur_page
			end
			self.auto_finish
			return true
		end
	end

	def load_question_by_ids(question_ids)
		questions = []
		question_ids.each do |q_id|
			question = Question.find_by_id(q_id)
			questions << question.remove_hidden_items(logic_control_result[q_id]["items"], logic_control_result[q_id]["sub_questions"])
		end
		return questions
	end

	#*description*: add a logic control result
	#
	#*params*:
	#* question_id
	#* items: array of inputs id that are added
	#* sub_questions: array of rows id that are added
	#
	#*retval*:
	#* true:
	#* false:
	def add_logic_control_result(question_id, items, sub_questions)
		if self.logic_control_result[question_id].nil?
			self.logic_control_result[question_id] = {"items" => items, "sub_questions" => sub_questions}
		else
			self.logic_control_result[question_id["items"]] = 
				(self.logic_control_result[question_id["items"]].to_a + items.to_a).uniq
			self.logic_control_result[question_id["sub_questions"]] = 
				(self.logic_control_result[question_id["sub_questions"]].to_a + items.to_a).uniq
		end
		return self.save
	end

	#*description*: remove a logic control result
	#
	#*params*:
	#* question_id
	#* items: array of inputs id that are removed
	#* sub_questions: array of rows id that are removed
	#
	#*retval*:
	#* true:
	#* false:
	def remove_logic_control_result(question_id, items, sub_questions)
		return if self.logic_control_result[question_id].nil?
		cur_items = self.logic_control_result[question_id]["items"].to_a
		cur_sub_questions = self.logic_control_result[question_id]["sub_questions"].to_a
		items.each do |ele|
			cur_items.delete(ele)
		end
		sub_questions.each do |ele|
			cur_sub_questions.delete(ele)
		end
		self.logic_control_result[question_id]["items"] = cur_items
		self.logic_control_result[question_id]["sub_questions"] = cur_sub_questions
		return self.save
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
				satisfy = Tool.check_choice_question_answer(self.answer_content[question_id]["selection"], require_answer)
			when "1"
				question_id = condition["name"]
				require_answer = condition["value"]
				satisfy = Tool.check_choice_question_answer(self.answer_content[question_id]["selection"], require_answer)
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
				volunteer_answer = self.answer_content[condition["name"]]["selection"]
				require_answer = condition["value"]
				# if the volunteer has not answered this question, cannot reject the volunteer
				satisfy = volunteer_answer.nil? || Tool.check_choice_question_answer(volunteer_answer, require_answer)
			when "1"
				volunteer_answer = self.answer_content[condition["name"]]["selection"]
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
		return ErrorEnum::WRONG_ANSWER_STATUS if !self.is_edit
		return ErrorEnum::SURVEY_NOT_ALLOW_PAGEUP if !self.survey.is_pageup_allowed
		return ErrorEnum::ANSWER_NOT_COMPLETE if self.template_answer_content.has_value?(nil)
		return ErrorEnum::ANSWER_NOT_COMPLETE if self.answer_content.has_value?(nil)
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
			volunteer_answer = self.answer_content[question_id]["selection"]
			case standard_answer.question_type
			when QuestionTypeEnum::CHOICE_QUESTION
				return Tool.check_choice_question_answer(self.answer_content[question_id]["selection"], 
					standard_answer.answer_content["items"],
					standard_answer.answer_content["fuzzy"])
			when QuestionTypeEnum::TEXT_BLANK_QUESTION
				return Tool.check_choice_question_answer(self.answer_content[question_id]["selection"], 
					standard_answer.answer_content["text"],
					standard_answer.answer_content["fuzzy"])
			when QuestionTypeEnum::NUMBER_BLANK_QUESTION
				return standard_answer.answer_content["number"] == self.answer_content[question_id]["selection"]
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
				v["selection"].each do |input_id|
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
		volunteer_answer_question_id_ary = answer_content.keys
		logic_control.each do |logic_control_rule|
			# only check the screen logic control rules
			next if logic_control_rule["rule_type"] != 0
			screen_condition_question_id_ary = logic_control_rule["conditions"].map {|ele| ele["question_id"]}
			# check whether, in the answers submitted, there are screen questions for this logic control rule
			target_question_id_ary = volunteer_answer_question_id_ary & screen_condition_question_id_ary
			next if target_question_id_ary.empty?

			# for each condition, check whether it is violated
			logic_control_rule["conditions"].each do |condition|
				# if the volunteer has not answered this question, stop the checking of this rule
				break if answer_content[condition["question_id"]].nil?
				pass_condition = Tool.check_choice_question_answer(answer_content[condition["question_id"]]["selection"], condition["answer"], condition["fuzzy"])
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

	def update_logic_control_result(answer_content)
		# array of ids of the questinos that the volunteer answers this time
		volunteer_answer_question_id_ary = answer_content.keys
		logic_control = self.survey.show_logic_control
		logic_control.each do |logic_control_rule|
			# array of ids of the quetions that are the conditions of this logic control rule
			logic_control_rule_question_id_ary = logic_control_rule["conditions"].map {|condition| condition["question_id"]}
			target_question_id_ary = volunteer_answer_question_id_ary & logic_control_rule_question_id_ary
			# if the answers submitted have nothing to do with the conditions of this rule, move to the next rule
			next if target_question_id_ary.empty?
			# if the conditions of the rule are not satisfied, move to the next rule
			satisfy_rule = true
			logic_control_rule["conditions"].each do |condition|
				# if the volunteer has not answered this question, stop the checking of this rule
				satisfy_rule = false if answer_content[condition["question_id"]].nil?
				pass_condition = Tool.check_choice_question_answer(answer_content[condition["question_id"]]["selection"], condition["answer"], condition["fuzzy"])
				satisfy_rule = false if !pass_condition
			end
			next if !satisfy_rule
			# the conditions of this logic control rule is satisfied
			case logic_control_rule["rule_type"]
			when 1
				# "show question" logic control
				# if the rule is satisfied, show the question (set the answer of the question as "nil")
				logic_control_rule["result"].each do |q_id|
					self.answer_content[q_id] = nil
				end
				self.save
			when 2
				# "hide question" logic control
				# if the rule is satisfied, hide the question (set the answer of the question as {})
				logic_control_rule["result"].each do |q_id|
					self.answer_content[q_id] = self.answer_content[q_id] || {}
				end
				self.save
			when 3
				# "show item" logic control
				# if the rule is satisfied, show the items (remove from the logic_control_result)
				logic_control_rule["result"].each do |ele|
					self.remove_logic_control_result(ele["question_id"], ele["items"], ele["sub_questions"])
				end
			when 4
				# "hide item" logic control
				# if the rule is satisfied, hide the items (add to the logic_control_result)
				logic_control_rule["result"].each do |ele|
					self.add_logic_control_result(ele["question_id"], ele["items"], ele["sub_questions"])
				end
			when 5
				# "show matching item" logic control
				# if the rule is satisfied, show the items (remove from the logic_control_result)
				items_to_be_removed = []
				log_control_rule["result"]["items"].each do |input_ids|
					items_to_be_removed << input_ids[1]
				end
				self.remove_logic_control_result(logic_control_rule["result"]["question_id_2"], items_to_be_removed, [])
			when 6
				# "hide matching item" logic control
				# if the rule is satisfied, hide the items (add to the logic_control_result)
				items_to_be_added = []
				log_control_rule["result"]["items"].each do |input_ids|
					items_to_be_added << input_ids[1]
				end
				self.add_logic_control_result(logic_control_rule["result"]["question_id_2"], items_to_be_added, [])
			end
		end
	end

	def auto_finish
		return ErrorEnum::WRONG_ANSWER_STATUS if !self.is_edit
		# those surveys that allow pageup cannot be finished automatically
		return ErrorEnum::SURVEY_ALLOW_PAGEUP if self.survey.is_pageup_allowed
		# check whether all questions are answered
		return ErrorEnum::ANSWER_NOT_COMPLETE if self.template_answer_content.has_value?(nil)
		return ErrorEnum::ANSWER_NOT_COMPLETE if self.answer_content.has_value?(nil)
		self.set_finish
		return true
	end
end
