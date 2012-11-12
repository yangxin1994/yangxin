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
	field :random_quality_control_answer_content, :type => Hash
	field :random_quality_control_locations, :type => Hash

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
	# finish_type: 0 for not reviewed, 1 for passing reviewed, 2 for rejected
	field :finish_type, :type => Integer, default: 0
	field :username, :type => String, default: ""
	field :password, :type => String, default: ""

	field :region, :type => Integer, default: -1
	field :channel, :type => Integer
	field :ip_address, :type => String, default: ""

	field :is_scanned, :type => Boolean, default: false

	field :is_preview, :type => Boolean, default: false

	field :finished_at, :type => Integer
	field :rejected_at, :type => Integer

	field :introducer_id, :type => String
	field :introducer_to_pay, :type => Integer

	scope :not_preview, lambda { where(:is_preview => false) }
	scope :preview, lambda { where(:is_preview => true) }

	scope :finished, lambda { where(:status => 2) }
	scope :screened, lambda { where(:status => 1, :reject_type => 2) }
	scope :finished_and_screened, lambda { any_of({:status => 2}, {:status => 1, :reject_type => 2}) }

	scope :unreviewed, lambda { where(:status => 2, :finish_type => 0) }

	belongs_to :user
	belongs_to :survey

	belongs_to :auditor, class_name: "User", inverse_of: :reviewed_answers

	STATUS_NAME_ARY = ["edit", "reject", "finish", "redo"]
	##### answer import #####


	def load_csv(survey=1)
		filename = "public/import/test.csv"
		CSV.foreach(filename, :headers => true) do |row|
			row.to_hash
		end
	end

	def self.def_status_attr
		STATUS_NAME_ARY.each_with_index do |status_name, index|
			define_method("is_#{status_name}".to_sym) { return index == self.status }
			define_method("set_#{status_name}".to_sym) { self.status = index; self.save}
		end
	end
	def_status_attr

	public

	def self.find_by_id(answer_id)
		answer = Answer.where(:_id => answer_id).first
		return answer
	end

	def self.find_by_survey_id_email_is_preview(survey_id, email, is_preview)
		survey = Survey.find_by_id(survey_id)
		owner = User.find_by_email(email)
		return nil if survey.nil?
		return nil if owner.nil?
		return survey.answers.where(user_id: owner._id.to_s, :is_preview => is_preview)[0]
	end	

	def self.find_by_password(username, password)
		answer = Answer.where(username: username, password: password)[0]
		return answer
	end

	def self.create_user_attr_survey_answer(operator, survey_id, answer_content)
		survey = Survey.find_by_id(survey_id)
		return ErrorEnum::SURVEY_NOT_EXIST if survey.nil?
		
		answer = Answer.new
		answer.answer_content = answer_content
		answer.save
		operator.answers << answer
		survey.answers << answer
		return true
	end

	def self.create_answer(is_preview, introducer_id, email, survey_id, channel, ip, username, password)
		survey = Survey.find_by_id(survey_id)
		return ErrorEnum::SURVEY_NOT_EXIST if survey.nil?
		answer = Answer.new(is_preview: is_preview, channel: channel, ip_address: ip, region: Address.find_address_code_by_ip(ip), username: username, password: password)
		if !is_preview
			answer.introducer_id = introducer_id
			answer.introducer_to_pay = survey.spread_point
		end
		
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

		answer.save
		if !email.nil?
			owner = User.find_by_email(email)
			owner.answers << answer if !owner.nil?
		end
		survey.answers << answer

		# initialize the logic control result
		answer.logic_control_result = {}
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

		# randomly generate quality control questions
		answer = answer.genereate_random_quality_control_questions

		return answer
	end

	def genereate_random_quality_control_questions
		quality_control_questions_ids = []
		self.random_quality_control_answer_content = {}
		self.random_quality_control_locations = {}
		if self.survey.is_random_quality_control_questions
			# need to select random questions
			# 1. determine the number of random quality control questions
			question_number = self.answer_content.length
			qc_question_number = [[question_number / 10, 1].max, 4].min
			objective_question_number = (qc_question_number / 2.0).ceil
			matching_question_number = qc_question_number - objective_question_number
			# 2. randomly choose questions and generate locations of questions
			objective_questions_ids = QualityControlQuestion.objective_questions.random(objective_question_number).map { |e| e._id.to_s }
			temp_matching_questions_ids = QualityControlQuestion.matching_questions.random(objective_question_number).map { |e| e._id.to_s }
			matching_questions_uniq_ids = []
			temp_matching_questions_ids.each do |m_q_id|
				matching_questions_uniq_ids += MatchingQuestion.get_matching_question_ids(m_q_id)
			end
			matching_questions_ids = matching_questions_uniq_ids.uniq
			quality_control_questions_ids = objective_questions_ids + matching_questions_ids
		else
			quality_control_questions_ids = self.survey.quality_control_questions_ids
		end

		# 3. random generate locations for the quality control questions
		quality_control_questions_ids.each do |qc_id|
			self.random_quality_control_locations[self.survey.all_questions_id.shuffle[0]] = qc_id
		end
		# 4. initialize the random quality control questions answers
		self.random_quality_control_answer_content = Hash[quality_control_questions_ids.map { |ele| [ele, nil] }]

		self.save
		return self
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
				next if question_id.to_s != "-1" && !page["questions"].include?(question_id)
				question_index = question_id.to_s == "-1" ? -1 : page["questions"].index(question_id)
				if next_page
					# require next page of questions
					if question_index + 1 == page["questions"].length
						return [] if page_index + 1 == self.survey.pages.length
						questions = load_question_by_ids(self.survey.pages[page_index + 1]["questions"])
						while questions.blank?
							# if the next page has no questions, try to load questions in the page after the next
							page_index = page_index + 1
							return [] if page_index + 1 == self.survey.pages.length
							questions = load_question_by_ids(self.survey.pages[page_index + 1]["questions"])
						end
						return questions
					else
						return load_question_by_ids(page["questions"][question_index + 1..-1])
					end
				else
					# require previous page of questions
					if question_index <= 0
						return [] if page_index == 0
						questions = load_question_by_ids(self.survey.pages[page_index - 1]["questions"])
						while questions.blank?
							# if the previous page has no questions, try to laod questions in the page before the previous
							page_index = page_index - 1
							return [] if page_index == 0
							questions = load_question_by_ids(self.survey.pages[page_index - 1]["questions"])
						end
						return questions
					else
						return load_question_by_ids(page["questions"][0..question_index - 1])
					end
				end
			end
			# the question cannot be found, load questions from the one with nil answer
			cur_page = false
			self.survey.pages.each do |page|
				page["questions"].each do |q_id|
					next if !self.answer_content[q_id].nil? && !cur_page
					cur_page = true
					loaded_question_ids << q_id
					qc_id = self.random_quality_control_locations[q_id]
					loaded_question_ids << qc_id if !qc_id.blank? && self.random_quality_control_answer_content[qc_id].nil?
				end
				return load_question_by_ids(loaded_question_ids) if cur_page
			end
			return []
		else
			# try to load normal questions
			# summarize the questions that are results of logic control rules
			logic_control_question_id = []
			self.survey.logic_control.each do |rule|
				result_q_ids = rule["result"] if ["1", "2"].include?(rule["type"])
				result_q_ids = rule["result"].map { |e| e["question_id"] } if ["3", "4"].include?(rule["type"])
				result_q_ids = rule["result"]["question_id_2"].to_a if ["5", "6"].include?(rule["type"])
				condition_q_ids = rule["conditions"].map {|condition| condition["question_id"]}
				logic_control_question_id << { "condition" => condition_question_id_ary, "result" => result_q_ids }
			end
			cur_page = false
			self.survey.pages.each do |page|
				page["questions"].each do |q_id|
					qc_id = self.random_quality_control_locations[q_id]
					if !self.answer_content[q_id].nil? && !cur_page
						# the question q_id might be removed by logic control rules, and the random quality control question after it is not answered
						loaded_question_ids << qc_id if !qc_id.blank? && self.random_quality_control_answer_content[qc_id].nil?
						next
					end
					# find out the first question whose answer is nil
					cur_page = true
					# check if this question is the result of some logic control rule
					logic_control_question_id.each do |ele|
						if !(ele["condition"] & loaded_question_ids).empty? && ele["result"].include?(q_id)
							return load_question_by_ids(loaded_question_ids)
						end
					end
					loaded_question_ids << q_id
					loaded_question_ids << qc_id if !qc_id.blank? && self.random_quality_control_answer_content[qc_id].nil?
				end
				return load_question_by_ids(loaded_question_ids) if cur_page
			end
			# it is possible that only several random quality control questions are loaded
			return load_question_by_ids(loaded_question_ids) if loaded_question_ids.length > 0
			# synchronize the questions in the survey and the qeustions in the answer content
			survey_question_ids = self.survey.pages.map { |page| page["questions"] }
			survey_question_ids = survey_question_ids.flatten
			self.answer_content.delete_if { |q_id, a| !survey_question_ids.include?(q_id) }
			survey_question_ids.each do |q_id|
				self.answer_content[q_id] ||= nil
			end
			self.save
			self.finish(true)
			return true
		end
	end

	def load_question_by_ids(question_ids)
		questions = []
		question_ids.each do |q_id|
			question = BasicQuestion.find_by_id(q_id)
			questions << question.remove_hidden_items(logic_control_result[q_id])
			# load random quality control quesitons for surveys that allow page up (no logic control)
			random_qc_id = self.random_quality_control_locations[q_id]
			if !random_qc_id.blank? && !question_ids.include?(random_qc_id)
				questions << BasicQuestion.find_by_id(random_qc_id)
			end
		end
		# consider the scenario that "one question per page"
		if self.survey.style_setting["is_one_question_per_page"]
			return questions[0]
		else
			return questions
		end
	end

	#*description*: add a logic control result, used for show/hide items logic control rules
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

	#*description*: called by "refresh_quota_stats" in survey.rb, check whether the answer satisfies the given conditions
	#
	#*params*:
	#* conditions: array, the conditions to be checked
	#
	#*retval*:
	#* true: when the conditions can be satisfied
	#* false: otherwise
	def satisfy_conditions(conditions, refresh_quota = true)
		# only answers that are finished contribute to quotas
		return false if !self.is_finish && refresh_quota
		# check the conditions one by one
		conditions.each do |condition|
			satisfy = false
			case condition["condition_type"].to_s
			when "0"
				question_id = condition["name"]
				require_answer = condition["value"]
				satisfy = Tool.check_choice_question_answer(self.answer_content[question_id]["selection"], require_answer, condition["fuzzy"])
			when "1"
				question_id = condition["name"]
				require_answer = condition["value"]
				satisfy = Tool.check_choice_question_answer(self.answer_content[question_id]["selection"], require_answer, condition["fuzzy"])
			when "2"
				satisfy = Address.satisfy_region_code?(self.region, condition["value"])
			when "3"
				satisfy = condition["value"] == self.channel.to_s
			when "4"
				satisfy = Tool.check_ip_mask(condition["value"], self.ip_address)
			end
			return satisfy if !satisfy
		end
		return true
	end

	#*description*: clear the answer contents, only work for answers with "redo" status, or preview answers, or answers whose survey allows pageup
	#
	#*params*:
	#
	#*retval*:
	#* true: when the answer content is cleared
	#* ErrorEnum::WRONG_ANSWER_STATUS
	def clear
		return ErrorEnum::WRONG_ANSWER_STATUS if self.is_finish || self.is_reject
		# clear the answer content
		self.answer_content.each_key do |k|
			self.answer_content[k] = nil
		end
		# clear the random quality control questions answer content
		self.random_quality_control_answer_content.each_key do |k|
			self.random_quality_control_answer_content[k] = nil
		end
		logic_control = self.survey.show_logic_control
		logic_control.each do |rule|
			if rule["rule_type"] == 1
				rule["result"].each do |q_id|
					answer_content[q_id] = {}
				end
			end
		end
		# initialize the logic control result
		self.logic_control_result = {}
		logic_control.each do |rule|
			if rule["rule_type"] == 3
				rule["result"].each do |ele|
					self.add_logic_control_result(ele["question_id"], ele["items"], ele["sub_questions"])
				end
			elsif rule["rule_type"] == 5
				items_to_be_added = []
				rule["result"]["items"].each do |input_ids|
					items_to_be_added << input_ids[1]
				end
				self.add_logic_control_result(rule["result"]["question_id_2"], items_to_be_added, [])
			end
		end

		# initialize the random quality control questions
		self.genereate_random_quality_control_questions if self.survey.is_random_quality_control_questions

		self.save
		self.set_edit
		return true
	end

	#*description*: check whether the answer expires and update the answer's status
	#
	#*params*:
	#
	#*retval*:
	#* the status of the answer after updating
	def update_status
		# an answer expires only when the survey is not published
		if Time.now.to_i - self.created_at.to_i > 2.days.to_i && self.survey.publish_status != 8
			self.set_reject
			self.update_attributes(reject_type: 3, rejected_at: Time.now.to_i)
		end
		return self.status
	end

	def delete
		# only answers that are finished can be deleted
		return ErrorEnum::WRONG_ANSWER_STATUS if self.is_redo || self.is_edit
		self.destroy
		return true
	end

	#*description*: update the answer content
	def update_answer(updated_answer_content)
		# it might happen that:
		# survey has a new question, but the answer content does not has the question id as a key
		# thus when updating the answer content, the key should not be checked
		updated_answer_content.each do |k, v|
			self.answer_content[k] = v
			self.random_quality_control_answer_content[k] = v if self.random_quality_control_answer_content.has_key?(k)
		end
		self.save
		return true
	end

	# the following three methods check the quality control, screen, and quota questions, respectively
	def check_quality_control(answer_content)
		# find out quality control questions
		random_quality_control_question_id_ary = []
		answer_content.each do |k, v|
			question = BasicQuestion.find_by_id(k)
			random_quality_control_question_id_ary << k if !question.nil? && question.class == QualityControlQuestion
		end
		# if there is no quality control questions, return
		return true if random_quality_control_question_id_ary.blank?
		########## all quality control quesoitns are randomly inserted ##########
		random_quality_control_question_id_ary.each do |qc_id|
			retval = QualityControlQuestion.check_quality_control_answer(qc_id, self.random_quality_control_answer_content[qc_id])
			if !retval
				# the quality control is violated
				self.repeat_time = self.repeat_time + 1 if self.repeat_time < 2
				self.save
				if self.repeat_time == 1
					self.set_redo
				else
					self.set_reject
					self.update_attributes(reject_type: 1, rejected_at: Time.now.to_i)
				end
				return false
			end
		end
		return true
	end

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
				if !pass_condition
					self.set_reject
					self.update_attributes(reject_type: 2, rejected_at: Time.now.to_i)
					return false
				end
			end
		end
		return true
	end

	def check_question_quota
		# 1. get the corresponding survey, quota, and quota stats
		quota = self.survey.show_quota
		quota_stats = self.survey.quota_stats
		# 2. if all quota rules are satisfied, the new answer should be rejected
		if quota_stats["quota_satisfied"]
			self.set_reject
			self.update_attributes(reject_type: 0, rejected_at: Time.now.to_i)
			return false
		end
		# 3 else, if the "is_exclusive" is set as false, the new answer should be accepted
		return true if !quota["is_exclusive"]
		# 4. check the rules one by one
		quota["rules"].each_with_index do |rule, rule_index|
			# find out a rule that:
			# a. the quota of the rule has not been satisfied
			# b. this answer satisfies the rule
			return true if quota_stats["answer_number"][rule_index] < rule["amount"] && self.satisfy_conditions(rule["conditions"], false)
		end
		self.set_reject
		self.update_attributes(reject_type: 0, rejected_at: Time.now.to_i)
		return false
	end

	def check_channel_ip_address_quota
		# 1. get the corresponding survey, quota, and quota stats
		quota = self.survey.quota
		quota_stats = self.survey.quota_stats
		# 2. if all quota rules are satisfied, the new answer should be rejected
		if quota_stats && quota_stats["quota_satisfied"]
			self.set_reject
			self.update_attributes(reject_type: 0, rejected_at: Time.now.to_i)
			return false
		end
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
				next if condition["condition_type"] == 2 && !Address.satisfy_region_code?(self.region, condition["value"])
				next if condition["condition_type"] == 3 && self.channel != condition["value"]
				next if condition["condition_type"] == 4 && Tool.check_ip_mask(self.ip_address, condition["value"])
			end
			# find out one rule. the quota for this rule has not been satisfied, and the answer does not violate conditions of the rule
			return true
		end
		# 5 cannot find a quota rule to accept this new answer
		self.set_reject
		self.update_attributes(reject_type: 0, rejected_at: Time.now.to_i)
		return false
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

	# return the index of the first given question in all the survey questions
	def index_of(questions)
		return nil if questions.blank?
		question_id = questions[0]._id.to_s
		question_ids = self.survey.all_questions_id
		return question_ids.index(question_id)
	end

	#*description*: finish an answer
	#
	#*params*:
	#
	#*retval*:
	#* true: when the answer is set as finished
	#* ErrorEnum::WRONG_ANSWER_STATUS
	#* ErrorEnum::SURVEY_NOT_ALLOW_PAGEUP
	#* ErrorEnum::ANSWER_NOT_COMPLETE
	def finish(auto = false)
		# surveys that allow page up cannot be finished automatically
		return false if self.survey.is_pageup_allowed && auto
		# synchronize the questions in the survey and the qeustions in the answer content
		survey_question_ids = self.survey.all_questions_id
		self.answer_content.delete_if { |q_id, a| !survey_question_ids.include?(q_id) }
		survey_question_ids.each do |q_id|
			self.answer_content[q_id] ||= nil
		end
		self.save
		# check whether can finish this answer
		return ErrorEnum::WRONG_ANSWER_STATUS if !self.is_edit
		return ErrorEnum::ANSWER_NOT_COMPLETE if self.answer_content.has_value?(nil)
		return ErrorEnum::ANSWER_NOT_COMPLETE if self.random_quality_control_answer_content.has_value?(nil)
		self.set_finish
		self.finished_at = Time.now.to_i
		self.save
		self.update_quota
		return true
	end

	def estimate_remain_answer_time
		remain_answer_time = 0.0
		self.survey.pages.each do |page|
			page["questions"].each do |q_id|
				q = BasicQuestion.find_by_id(q_id)
				remain_answer_time = remain_answer_time + q.estimate_answer_time if self.answer_content[q_id].nil? && !q.nil?
			end
		end
		return remain_answer_time
	end

	def update_quota
		quota_stats = self.survey.quota_stats
		quota_rules = self.survey.quota["rules"]
		quota_rules.each_with_index do |rule, rule_index|
			if self.satisfy_conditions(rule["conditions"])
				quota_stats["answer_number"][rule_index] = quota_stats["answer_number"][rule_index] + 1
			end
		end
		self.survey.save
	end

	# the answer auditor reviews this answer, the review result can be 1 (pass review) or 2 (not pass)
	def review(review_result, answer_auditor)
		return ErrorEnum::ANSWER_NOT_FINISHED if self.status != 2
		self.finish_type = review_result.to_i == 1 ? 1 : 2
		self.auditor = answer_auditor
		self.save
		# no need to give points if the answer does not pass the review
		return if self.finish_type == 2
		if [1,2].include?(self.survey.reward)
			# assign this user points, or a loterry code
			# usage post_reward_to(user, :type => 2, :point => 100)
			# 1 for lottery & 2 for point
			lc = self.survey.reward == 1 ? nil : self.survey.lottery.give_lottery_code_to(user)
			return ErrorEnum::REWARD_ERROR unless self.survey.post_reward_to(user, 
																			:type => self.survey.reward, 
																			:point => self.survey.point,
																			:lottery_code => lc,
																			:cause => 2)
		end
		# give the introducer points
		introducer = User.find_by_id(self.introducer_id)
		if !introducer.nil? && introducer_to_pay > 0
			RewardLog.create(:user => introducer, :type => 2, :point => self.introducer_to_pay, :extended_survey_id => self.survey_id, :cause => 3)
			# send the introducer a message about the rewarded points
			user.create_message("问卷推广积分奖励", "您推荐填写的问卷通过了审核，您获得了#{self.introducer_to_pay}个积分奖励。", [introducer._id])
		end
		return true
	end

end
