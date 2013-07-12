# encoding: utf-8
require 'error_enum'
require 'securerandom'
require 'tool'
require 'quill_common'
class Answer
	include Mongoid::Document
	include Mongoid::Timestamps
	# status: 1 for editting, 2 for reject, 4 for under review, 8 for finish, 16 for redo
	field :status, :type => Integer, default: 0
	field :answer_content, :type => Hash, default: {}
	field :random_quality_control_answer_content, :type => Hash, default: {}
	field :random_quality_control_locations, :type => Hash, default: {}
	# Due to the logic control rules, volunteer's answer will hide/show some questions/choices.
	# The hide/show of questions can be recorded in the "answer_content" field
	# => For those questions that are hidden, their answers are set as "{}", and they will not be loaded
	# The hide/show of choices is recorded in he logic_control_result
	# => Specifically, logic_control_result is used to record those choices that are hidden.
	# => logic_control_result is a hash, the key of which is question id, and the value of which has the following strucutre
	# => => items : array of input ids that are hidden
	# => => sub_questions : array of row ids that are hidden
	field :logic_control_result, :type => Hash, default: {}
	field :repeat_time, :type => Integer, default: 0
	# reject_type: 1 for rejected by quota, 2 for rejected by quliaty control (auto quality control), 4 for rejected by manual quality control, 8 for rejected by screen, 16 for timeout
	field :reject_type, :type => Integer
	field :username, :type => String, default: ""
	field :password, :type => String, default: ""
	field :region, :type => Integer, default: -1
	#channel: 1（调研社区）2（邮件订阅），4（短信订阅），8（浏览器插件推送），16（微博发布），32（Folwy发布），64（线上代理发布)
	field :channel, :type => Integer
	field :ip_address, :type => String, default: ""
	field :is_scanned, :type => Boolean, default: false
	field :is_preview, :type => Boolean, default: false
	field :finished_at, :type => Integer
	field :import_id, :type => String
	# audit time
	field :audit_at, :type => Integer
	# audit message content
	field :audit_message, :type => String, default: ""
	field :introducer_id, :type => String
	field :point_to_introducer, :type => Integer
	field :point, :type => Integer, :default => 0
	field :rewards, :type => Array, :default => []
	field :introducer_reward_assigned, :type => Boolean, default: false
	field :reward_delivered, :type => Boolean, default: false
	field :need_review, :type => Boolean

	# used for interviewer to upload attachments
	field :attachment, :type => Hash, :default => {}
	field :longitude, :type => String, :default => ""
	field :latitude, :type => String, :default => ""
	field :referrer, :type => String, :default => ""

	scope :not_preview, lambda { where(:is_preview => false) }
	scope :preview, lambda { where(:is_preview => true) }
	scope :finished, lambda { where(:status => 3) }
	scope :screened, lambda { where(:status => 1, :reject_type => 3) }
	scope :finished_and_screened, lambda { any_of({:status => 3}, {:status => 1, :reject_type => 3}) }
	scope :rejected, lambda { where(:status => 1) }
	scope :unreviewed, lambda { where(:status => 2) }
	scope :ongoing, lambda {where(:status => 0)}
	scope :wait_for_review, lambda {where(:status => 2)}

	belongs_to :agent_task
	belongs_to :user, class_name: "User", inverse_of: :answers
	belongs_to :agent_task
	belongs_to :survey
	belongs_to :interviewer_task
	belongs_to :lottery
	belongs_to :auditor, class_name: "User", inverse_of: :reviewed_answers
	has_one :order

	STATUS_NAME_ARY = ["edit", "reject", "under_review", "finish", "redo"]
	EDIT = 1
	REJECT = 2
	UNDER_REVIEW = 4
	FINISH = 8
	REDO = 16
	##### answer import #####

	index({ survey_id: 1, status: 1, reject_type: 1 }, { background: true } )
	index({ survey_id: 1, is_preview: 1 }, { background: true } )
	index({ username: 1, password: 1 }, { background: true } )
	index({ user_id: 1 }, { background: true } )
	index({ is_preview: 1, introducer_id: 1 }, { background: true } )

	def load_csv(survey=1)
		filename = "public/import/test.csv"
		CSV.foreach(filename, :headers => true) do |row|
			row.to_hash
		end
	end

	def self.def_status_attr
		STATUS_NAME_ARY.each_with_index do |status_name, index|
			define_method("is_#{status_name}".to_sym) { return 2**index == self.status }
			define_method("set_#{status_name}".to_sym) { self.status = 2**index; self.save}
		end
	end
	def_status_attr

	public

	def self.find_by_id(answer_id)
		return Answer.where(:_id => answer_id).first
	end

	def self.find_by_survey_id_sample_id_is_preview(survey_id, sample_id, is_preview)
		return Answer.where(user_id: sample_id, survey_id: survey_id, :is_preview => is_preview).first
	end

	def self.find_by_status(status)
		return self.in("status" => Tool.convert_int_to_base_arr(status.to_i))
	end

	def self.create_answer(survey_id, reward_scheme_id, is_preview, introducer_id, channel, referrer, remote_ip, username, password)
		# create the answer
		answer = Answer.new(is_preview: is_preview,
			channel: channel,
			ip_address: ip,
			region: QuillCommon::AddressUtility.find_address_code_by_ip(ip),
			username: username,
			password: password,
			referrer: referrer)
		# record introducer information
		if !is_preview && introducer_id
			introducer = User.sample.find_by_id(introducer_id)
			if !introducer.nil?
				answer.introducer_id = introducer_id
				answer.point_to_introducer = survey.spread_point
			end
		end
		# record the reward information
		reward_scheme = RewardScheme.find_by_id(reward_scheme_id)
		if !reward_scheme.nil?
			answer.rewards = reward_scheme.rewards
			answer.rewards[0]["checked"] = true if answer.rewards.length == 1
			answer.need_review = reward_scheme.need_review
			reward_scheme.answers << self
		else
			answer.rewards = []
			answer.need_review = false
		end

		answer.save
		survey = Survey.normal.find_by_id(survey_id)
		survey.answers << answer
	end

	def has_rewards
		return !self.rewards.blank?
	end

	def is_screened
		return status == 1 && reject_type == 3
	end

	def genereate_random_quality_control_questions
		quality_control_questions_ids = []
		self.random_quality_control_answer_content = {}
		self.random_quality_control_locations = {}
		if self.answer_content.blank?
			# when there are no normal questions, it is not needed to generate random quality control questions
			self.save
			return self
		end
		if self.survey.is_random_quality_control_questions
			# need to select random questions
			# 1. determine the number of random quality control questions
			question_number = self.answer_content.length
			qc_question_number = [[question_number / 10, 1].max, 4].min
			objective_question_number = (qc_question_number / 2.0).ceil
			matching_question_number = qc_question_number - objective_question_number
			# 2. randomly choose questions and generate locations of questions
			objective_questions_ids = QualityControlQuestion.objective_questions.random(objective_question_number).map { |e| e._id.to_s }
			temp_matching_questions_ids = QualityControlQuestion.matching_questions.random(matching_question_number).map { |e| e._id.to_s }
			matching_questions_ids = []
			temp_matching_questions_ids.each do |m_q_id|
				matching_questions_ids += MatchingQuestion.get_matching_question_ids(m_q_id)
			end
			quality_control_questions_ids = objective_questions_ids + matching_questions_ids
		else
			self.survey.quality_control_questions_ids.each do |qc_id|
				quality_control_question = QualityControlQuestion.find_by_id(qc_id)
				next if quality_control_question.nil?
				if quality_control_question.quality_control_type == 1
					# objective quality control question
					quality_control_questions_ids << qc_id
				else
					# matching quality control question
					quality_control_questions_ids += MatchingQuestion.get_matching_question_ids(qc_id)
				end
			end
		end
		quality_control_questions_ids.uniq!

		# 3. random generate locations for the quality control questions
		quality_control_questions_ids.each do |qc_id|
			normal_question_id = self.survey.all_questions_id.shuffle[0]
			self.random_quality_control_locations[normal_question_id] ||= []
			self.random_quality_control_locations[normal_question_id] << qc_id
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
		pages = self.survey.pages.map { |p| p["questions"] }
		pages_with_qc_questions = []
		pages.each do |page_question_ids|
			cur_page_questions = []
			page_question_ids.each do |q_id|
				cur_page_questions << q_id
				qc_ids = self.random_quality_control_locations[q_id] || []
				cur_page_questions += qc_ids
			end
			pages_with_qc_questions << cur_page_questions
		end
		# consider the following scenario:
		# a normal question is removed, there are quality control questions after this normal question
		# such quality control questions are added to the last page
		current_all_questions = pages_with_qc_questions.flatten
		remain_qc_ids = []
		self.random_quality_control_answer_content.each do |k, v|
			remain_qc_ids << k if !current_all_questions.include?(k)
		end
		pages_with_qc_questions << remain_qc_ids if !remain_qc_ids.blank?

		if self.survey.is_pageup_allowed
			# begin to find the question given
			pages_with_qc_questions.each_with_index do |page_questions, page_index|
				next if question_id.to_s != "-1" && !page_questions.include?(question_id)
				question_index = question_id.to_s == "-1" ? -1 : page_questions.index(question_id)
				if next_page
					if question_index + 1 == page_questions.length
						# should load next page questions
						return load_question_by_ids([]) if page_index + 1 == pages_with_qc_questions.length
						questions_ids = pages_with_qc_questions[page_index + 1]
						while questions_ids.blank?
							# if the next page has no questions, try to load questions in the page after the next
							page_index = page_index + 1
							return load_question_by_ids([]) if page_index + 1 == pages_with_qc_questions.length
							questions_ids = pages_with_qc_questions[page_index + 1]
						end
						return load_question_by_ids(questions_ids, next_page)
					else
						# should load remaining questions in the current page
						return load_question_by_ids(page_questions[question_index + 1..-1], next_page)
					end
				else
					if question_index <= 0
						# should load previous page questions
						return load_question_by_ids([]) if page_index == 0
						questions_ids = pages_with_qc_questions[page_index - 1]
						while questions_ids.blank?
							# if the previous page has no questions, try to laod questions in the page before the previous
							page_index = page_index - 1
							return load_question_by_ids([]) if page_index == 0
							questions_ids = pages_with_qc_questions[page_index - 1]
						end
						return load_question_by_ids(questions_ids, next_page)
					else
						# should load remaining questions in the current page
						return load_question_by_ids(page_questions[0..question_index - 1], next_page)
					end
				end
			end
			# the question cannot be found, load questions from the one with nil answer
			loaded_question_ids = []
			cur_page = false
			pages_with_qc_questions.each_with_index do |page_questions, page_index|
				page_questions.each do |q_id|
					# go to the next one if this questions has been answered
					next if ( !self.answer_content[q_id].nil? || !self.random_quality_control_answer_content[q_id].nil? ) && !cur_page
					cur_page = true
					loaded_question_ids << q_id
				end
				return load_question_by_ids(loaded_question_ids, next_page) if cur_page
			end
			return load_question_by_ids([])
		else
			loaded_question_ids = []
			# try to load normal questions
			# summarize the questions that are results of logic control rules
			logic_control_question_id = []
			self.survey.logic_control.each do |rule|
				if rule["rule_type"] == 0
					all_questions_id = self.survey.all_questions_id
					max_condition_index = -1
					rule["conditions"].each do |c|
						cur_index = all_questions_id.index(c["question_id"])
						max_condition_index = cur_index if !cur_index.nil? && cur_index > max_condition_index
					end
					result_q_ids = all_questions_id[max_condition_index+1..-1] if max_condition_index != -1
				end
				result_q_ids = rule["result"] if ["1", "2"].include?(rule["rule_type"].to_s)
				result_q_ids = rule["result"].map { |e| e["question_id"] } if ["3", "4"].include?(rule["rule_type"].to_s)
				result_q_ids = rule["result"]["question_id_2"].to_a if ["5", "6"].include?(rule["rule_type"].to_s)
				condition_q_ids = rule["conditions"].map {|condition| condition["question_id"]}
				logic_control_question_id << { "condition" => condition_q_ids, "result" => result_q_ids || [] }
			end
			cur_page = false
			pages_with_qc_questions.each do |page_questions|
				page_questions.each do |q_id|
					# check if this question is the result of some logic control rule
					if cur_page
						logic_control_question_id.each do |ele|
							if !(ele["condition"] & loaded_question_ids).empty? && ele["result"].include?(q_id)
								return load_question_by_ids(loaded_question_ids)
							end
						end
					end
					next if ( !self.answer_content[q_id].nil? || !self.random_quality_control_answer_content[q_id].nil? )
					cur_page = true
					loaded_question_ids << q_id
				end
				return load_question_by_ids(loaded_question_ids) if cur_page
			end
			return load_question_by_ids([])
		end
	end

	def load_question_by_ids(question_ids, next_page = true)
		if question_ids.blank? && !self.survey.is_pageup_allowed
			# try to automatically finish the survey if:
			# 1. no questions to load
			# 2. page up is now allowed
			finish(true)
		end
		questions = []
		question_ids.each do |q_id|
			question = BasicQuestion.find_by_id(q_id)
			questions << question.remove_hidden_items(logic_control_result[q_id]) if !question.nil?
		end
		# consider the scenario that "one question per page"
		if self.survey.style_setting["is_one_question_per_page"]
			if questions.blank?
				return []
			elsif next_page
				# should return the first question
				return [questions[0]]
			else
				# should return the last question
				return [questions[-1]]
			end
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
		return if self.survey.is_pageup_allowed
		if self.logic_control_result[question_id].nil?
			self.logic_control_result[question_id] = {"items" => items, "sub_questions" => sub_questions}
		else
			self.logic_control_result[question_id]["items"] =
				(self.logic_control_result[question_id]["items"].to_a + items.to_a).uniq
			self.logic_control_result[question_id]["sub_questions"] =
				(self.logic_control_result[question_id]["sub_questions"].to_a + sub_questions.to_a).uniq
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
		return if self.survey.is_pageup_allowed
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
			when "1"
				question_id = condition["name"]
				question = BasicQuestion.find_by_id(question_id)
				if question.nil?
					satisfy = true
				else
					require_answer = condition["value"]
					if answer_content[question_id].nil?
						satisfy = true
					elsif question.question_type == QuestionTypeEnum::CHOICE_QUESTION
						satisfy = Tool.check_choice_question_answer(question_id,
																self.answer_content[question_id]["selection"],
																require_answer,
																condition["fuzzy"])
					elsif question.question_type == QuestionTypeEnum::ADDRESS_BLANK_QUESTION
						satisfy = Tool.check_address_blank_question_answer(question_id,
																self.answer_content[question_id]["selection"],
																require_answer)
					end
				end
			when "2"
				satisfy = QuillCommon::AddressUtility.satisfy_region_code?(self.region, condition["value"])
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
		self.genereate_random_quality_control_questions

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
		# an answer expires only when the survey is not published and the answer is in editting status
		if Time.now.to_i - self.created_at.to_i > 2.days.to_i && self.survey.publish_status != 8 && self.status == 0
			self.set_reject
			self.update_attributes(reject_type: 4, finished_at: Time.now.to_i)
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
			self.answer_content[k] = v if self.answer_content.has_key?(k)
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
			retval = QualityControlQuestion.check_quality_control_answer(qc_id, self)
			if !retval
				# the quality control is violated
				self.repeat_time = self.repeat_time + 1 if self.repeat_time < 2
				self.save
				if self.repeat_time == 1
					self.set_redo
				else
					self.set_reject
					self.update_attributes(reject_type: 1, finished_at: Time.now.to_i)
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
				pass_condition = Tool.check_choice_question_answer(answer_content[condition["question_id"]],
																answer_content[condition["question_id"]]["selection"],
																condition["answer"],
																condition["fuzzy"])
				if pass_condition
					self.set_reject
					self.update_attributes(reject_type: 3, finished_at: Time.now.to_i)
					return false
				end
			end
		end
		return true
	end

	def check_question_quota
		# 1. get the corresponding survey, quota, and quota stats
		quota = self.survey.show_quota
		# 2. if all quota rules are satisfied, the new answer should be rejected
		if quota["quota_satisfied"]
			self.set_reject
			self.update_attributes(reject_type: 0, finished_at: Time.now.to_i)
			return false
		end
		# 3 else, if the "is_exclusive" is set as false, the new answer should be accepted
		return true if !quota["is_exclusive"]
		# 4. check the rules one by one
		quota["rules"].each do |rule|
			# find out a rule that:
			# a. the quota of the rule has not been satisfied
			# b. this answer satisfies the rule
			return true if rule["submitted_count"] < rule["amount"] && self.satisfy_conditions(rule["conditions"], false)
		end
		self.set_reject
		self.update_attributes(reject_type: 0, finished_at: Time.now.to_i)
		return false
	end

	def check_channel_ip_address_quota
		# 1. get the corresponding survey, quota, and quota stats
		quota = self.survey.quota
		# 2. if all quota rules are satisfied, the new answer should be rejected
		if quota["quota_satisfied"]
			self.set_reject
			self.update_attributes(reject_type: 0, finished_at: Time.now.to_i)
			return false
		end
		# 3 else, if the "is_exclusive" is set as false, the new answer should be accepted
		return true if !quota["is_exclusive"]
		# 4 the rules should be checked one by one to see whether this answer can be satisfied
		quota["rules"].each do |rule|
			# move to next rule if the quota of this rule is already satisfied
			next if rule["submitted_count"] >= rule["amount"]
			rule["conditions"].each do |condition|
				# if the answer's ip, channel, or region violates one condition of the rule, move to the next rule
				next if condition["condition_type"] == 2 && !QuillCommon::AddressUtility.satisfy_region_code?(self.region, condition["value"])
				next if condition["condition_type"] == 3 && self.channel != condition["value"]
				next if condition["condition_type"] == 4 && Tool.check_ip_mask(self.ip_address, condition["value"])
			end
			# find out one rule. the quota for this rule has not been satisfied, and the answer does not violate conditions of the rule
			return true
		end
		# 5 cannot find a quota rule to accept this new answer
		self.set_reject
		self.update_attributes(reject_type: 0, finished_at: Time.now.to_i)
		return false
	end

	def update_logic_control_result(answer_content)
		return if self.survey.is_pageup_allowed
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
				pass_condition = Tool.check_choice_question_answer(condition["question_id"],
																answer_content[condition["question_id"]]["selection"],
																condition["answer"],
																condition["fuzzy"])
				satisfy_rule = false if !pass_condition
			end
			next if !satisfy_rule
			# the conditions of this logic control rule is satisfied
			case logic_control_rule["rule_type"].to_s
			when "1"
				# "show question" logic control
				# if the rule is satisfied, show the question (set the answer of the question as "nil")
				logic_control_rule["result"].each do |q_id|
					self.answer_content[q_id] = nil
				end
				self.save
			when "2"
				# "hide question" logic control
				# if the rule is satisfied, hide the question (set the answer of the question as {})
				logic_control_rule["result"].each do |q_id|
					self.answer_content[q_id] = self.answer_content[q_id] || {}
				end
				self.save
			when "3"
				# "show item" logic control
				# if the rule is satisfied, show the items (remove from the logic_control_result)
				logic_control_rule["result"].each do |ele|
					self.remove_logic_control_result(ele["question_id"], ele["items"], ele["sub_questions"])
				end
			when "4"
				# "hide item" logic control
				# if the rule is satisfied, hide the items (add to the logic_control_result)
				logic_control_rule["result"].each do |ele|
					self.add_logic_control_result(ele["question_id"], ele["items"], ele["sub_questions"])
				end
			when "5"
				# "show matching item" logic control
				# if the rule is satisfied, show the items (remove from the logic_control_result)
				items_to_be_removed = []
				log_control_rule["result"]["items"].each do |input_ids|
					items_to_be_removed << input_ids[1]
				end
				self.remove_logic_control_result(logic_control_rule["result"]["question_id_2"], items_to_be_removed, [])
			when "6"
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
		question_id = nil
		questions.each do |q|
			if q.question_type != QuestionTypeEnum::PARAGRAPH
				question_id = q._id.to_s
				break
			end
		end
		return nil if question_id.nil?
		question_ids = self.survey.all_questions_id(false)
		question_ids_with_qc_questions = []
		question_ids.each do |qid|
			question_ids_with_qc_questions << qid
			question_ids_with_qc_questions += self.random_quality_control_locations[qid] if !self.random_quality_control_locations[qid].blank?
		end
		return question_ids_with_qc_questions.index(question_id)
	end

	def finish(auto = false)
		# synchronize the normal questions in the survey and the qeustions in the answer content
		survey_question_ids = self.survey.all_questions_id
		self.answer_content.delete_if { |q_id, a| !survey_question_ids.include?(q_id) }
		survey_question_ids.each do |q_id|
			self.answer_content[q_id] ||= nil
		end
		self.random_quality_control_answer_content.delete_if { |q_id, a| QualityControlQuestion.find_by_id(q_id).nil? }
		self.save
		# surveys that allow page up cannot be finished automatically
		return false if self.survey.is_pageup_allowed && auto
		# check whether can finish this answer
		return ErrorEnum::WRONG_ANSWER_STATUS if !self.is_edit
		return ErrorEnum::ANSWER_NOT_COMPLETE if self.answer_content.has_value?(nil)
		return ErrorEnum::ANSWER_NOT_COMPLETE if self.random_quality_control_answer_content.has_value?(nil)
		old_status = self.status
		# if the survey has no prize and cannot be spreadable (or spread reward point is 0), set the answer as finished
		if self.is_preview || self.need_review
			self.set_finish
		else
			self.set_under_review
		end
		self.update_quota(old_status) if !self.is_preview
		self.finished_at = Time.now.to_i
		return self.save
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

	def update_quota(old_status)
		quota = self.survey.quota
		if old_status == EDIT && self.is_under_review
			# user submits the answer
			quota["submitted_count"] += 1
		elsif old_status == EDIT && self.is_finish
			# user submits the answer, and the answer automatically passes review
			quota["submitted_count"] += 1
			quota["finished_count"] += 1
		elsif old_status == UNDER_REVIEW && self.is_finish
			# answer passes review
			quota["finished_count"] += 1
		elsif old_status == UNDER_REVIEW && self.is_reject
			# answer fails review
			quota["submitted_count"] = [quota["submitted_count"].to_i - 1, 0].max
		end
		quota["rules"].each do |rule|
			next if !self.satisfy_conditions(rule["conditions"], false)
			if old_status == EDIT && self.is_under_review
				# user submits the answer
				rule["submitted_count"] += 1
			elsif old_status == EDIT && self.is_finish
				# user submits the answer, and the answer automatically passes review
				rule["submitted_count"] += 1
				rule["finished_count"] += 1
			elsif old_status == UNDER_REVIEW && self.is_finish
				# answer passes review
				rule["finished_count"] += 1
			elsif old_status == UNDER_REVIEW && self.is_reject
				# answer fails review
				rule["submitted_count"] = [rule["submitted_count"] - 1, 0].max
			end
		end
		self.survey.save
	end

	# the answer auditor reviews this answer, the review result can be 1 (pass review) or 2 (not pass)
	def review(review_result, answer_auditor, message_content)
		return ErrorEnum::WRONG_ANSWER_STATUS if self.status != UNDER_REVIEW

		old_status = self.status
		user = self.user

		# execute the review operation
		if review_result
			self.set_finish
			message_content ||= "你的此问卷[#{self.survey.title}]的答案通过审核."
		else
			self.set_reject
			self.reject_type = REJECT
			message_content ||= "你的此问卷[#{self.survey.title}]的答案未通过审核."
		end
		answer_auditor.create_message("审核问卷答案消息", message_content, [user._id.to_s]) if !user.nil?
		self.audit_message = message_content
		self.auditor = answer_auditor
		self.audit_at = Time.now.to_i
		self.save

		# update quota of the survey and the interviewer task if there is any
		self.interviewer_task.try(:refresh_quota)
		self.update_quota(old_status)
		self.deliver_reward
		return true
	end

	def assign_introducer_reward
		# give the introducer points
		introducer = User.find_by_id(self.introducer_id)
		if !introducer.nil? && self.introducer_reward_assigned == false
			# update the survey spread
			SurveySpread.inc(introducer, self.survey)
			if point_to_introducer > 0
				RewardLog.create(:user => introducer, :type => 2, :point => self.point_to_introducer, :extended_survey_id => self.survey_id, :cause => 3)
				# send the introducer a message about the rewarded points
				introducer.create_message("问卷推广积分奖励", "您推荐填写的问卷通过了审核，您获得了#{self.point_to_introducer}个积分奖励。", [introducer._id.to_s])
			end
			self.introducer_reward_assigned = true
		end
	end

	def change_sample_account(sample)
		sample.answers.delete(self) if !self.user.nil?
		sample.answers << self
		return true
	end

	def logout_sample_account
		self.user.answers.delete(self) if !self.user.nil?
	end

	def select_reward(reward_index, mobile, alipay_account)
		# select reward
		reward = self.rewards[reward_index]
		return ErrorEnum::REWARD_NOT_EXIST if reward.nil?
		self.rewards.each { |r|	r["checked"] = false }
		reward["checked"] = true

		# record the mobile or alipay account
		if reward["type"].to_i == RewardScheme::MOBILE
			# need to record mobile number
			reward["mobile"] = mobile
		elsif [RewardScheme::ALIPAY, RewardScheme::JIFENBAO].include?(reward["type"].to_i)
			# need to record alipay account
			reward["alipay_account"] = alipay_account
		end
		self.save

		return self.deliver_reward
	end

	def deliver_reward
		# reward has been delivered
		return true if self.reward_delivered

		# find out the selected reward
		reward = nil
		self.rewards.each do |r|
			reward = r and break if r["checked"] == true
		end
		return ErrorEnum::REWARD_NOT_SELECTED if reward.nil?
		
		case reward["type"].to_i
		when RewardScheme::MOBILE
			return ErrorEnum::REPEAT_ORDER if self.survey.answers.check_repeat_mobile(reward["mobile"])
			return ErrorEnum::ANSWER_NEED_REVIEW if self.status == UNDER_REVIEW
			sample = User.find_or_create_new_visitor_by_email_mobile(reward["mobile"])
			order = Order.create_answer_order(sample._id.to_s,
				self.survey._id.to_s,
				Order::SMALL_MOBILE_CHARGE,
				reward["amount"],
				"mobile" => reward["mobile"])
			self.order = order
			assign_introducer_reward
			self.reward_delivered = true
			return self.save
		when RewardScheme::ALIPAY
			return ErrorEnum::REPEAT_ORDER if self.survey.answers.check_repeat_alipay(reward["alipay_account"])
			return ErrorEnum::ANSWER_NEED_REVIEW if self.status == UNDER_REVIEW
			sample = User.find_or_create_new_visitor_by_email_mobile(reward["alipay_account"])
			order = Order.create_answer_order(sample._id.to_s,
				self.survey._id.to_s,
				Order::ALIPAY,
				reward["amount"],
				"alipay_account" => reward["alipay_account"])
			self.order = order
			assign_introducer_reward
			self.reward_delivered = true
			return self.save
		when RewardScheme::JIFENBAO
			return ErrorEnum::REPEAT_ORDER if self.survey.answers.check_repeat_jifenbao(reward["alipay_account"])
			return ErrorEnum::ANSWER_NEED_REVIEW if self.status == UNDER_REVIEW
			sample = User.find_or_create_new_visitor_by_email_mobile(reward["alipay_account"])
			order = Order.create_answer_order(sample._id.to_s,
				self.survey._id.to_s,
				Order::JIFENBAO,
				reward["amount"],
				"alipay_account" => reward["alipay_account"])
			self.order = order
			assign_introducer_reward
			self.reward_delivered = true
			return self.save
		when RewardScheme::POINT
			return ErrorEnum::SAMPLE_NOT_EXIST if self.user.nil?
			return ErrorEnum::ANSWER_NEED_REVIEW if self.status == UNDER_REVIEW
			sample = self.user
			sample.point += reward["amount"]
			assign_introducer_reward
			self.reward_delivered = true
			return self.save
		when RewardScheme::LOTTERY
			return true if self.status == UNDER_REVIEW
			assign_introducer_reward
			order = self.order
			if order && order.status == Order::FROZEN
				order.status = Order::WAIT
				order.save
				order.auto_handle
			end
			return true
		end
	end

	def self.check_repeat_mobile(mobile)
		self.all.each do |a|
			selected_reward = a.rewards.select { |r| r["checked"] == true }
			next if selected_reward.blank?
			return true if selected_reward[0]["type"] == RewardScheme::MOBILE && selected_reward[0]["mobile"] == mobile
		end
		return false
	end

	def self.check_repeat_alipay(alipay_account)
		self.all.each do |a|
			selected_reward = a.rewards.select { |r| r["checked"] == true }
			next if selected_reward.blank?
			return true if selected_reward[0]["type"] == RewardScheme::ALIPAY && selected_reward[0]["alipay_account"] == alipay_account
		end
		return false
	end

	def self.check_repeat_jifenbao(alipay_account)
		self.all.each do |a|
			selected_reward = a.rewards.select { |r| r["checked"] == true }
			next if selected_reward.blank?
			return true if selected_reward[0]["type"] == RewardScheme::JIFENBAO && selected_reward[0]["alipay_account"] == alipay_account
		end
		return false
	end

	def bind_sample(email_mobile)
		sample = User.find_or_create_new_visitor_by_email_mobile(email_mobile)
		answer = Answer.find_by_survey_id_sample_id_is_preview(self.survey._id, sample._id, false)
		return ErrorEnum::ANSWER_EXIST if !answer.nil?
		sample.answers << self
		return self.deliver_reward
	end

	def draw_lottery
		return ErrorEnum::LOTTERY_DRAWED if self.reward_delivered
		reward = (self.rewards.select { |r| r["checked"] == true }).first
		return ErrorEnum::REWORD_NOT_SELECTED if reward.nil?
		return ErrorEnum::NOT_LOTTERY_REWARD if reward["type"] != RewardScheme::LOTTERY
		return ErrorEnum::LOTTERY_DRAWED if !reward["win"].nil?

		# draw lottery
		reward_scheme = self.reward_scheme
		reward_index = -1
		reward_scheme.rewards.each_with_index do |r, i|
			if r["type"] == RewardScheme::LOTTERY
				reward_index = i
				break
			end
		end
		if reward_index == -1
			self.reward_delivered = true
			self.save
			return false
		end
		prizes = reward["prizes"]
		return ErrorEnum::REWARD_SCHEME_NOT_EXIST if reward_scheme.nil?
		reward["prizes"].each do |p|
			next if rand > p["prob"]
			prizes.each do |reward_scheme_p|
				next if p["prize_id"] != reward_scheme_p["prize_id"]
				if reward_scheme_p["deadline"] < Time.now.to_i && reward_scheme_p["amount"] > reward_scheme_p["win_amount"]
					# win lottery
					reward["win"] = true
					reward["prize_id"] = p["prize_id"]
					self.save
					reward_scheme_p["win_amount"] ||= 0
					reward_scheme_p["win_amount"] += 1
					reward_scheme.save
					return p["prize_id"]
				end
			end
		end
		reward["win"] = false
		self.reward_delivered = true
		self.save
		return false
	end

	def create_lottery_order(order_info)
		return ErrorEnum::SAMPLE_NOT_EXIST if self.user.nil?
		return ErrorEnum::ORDER_CREATED if !self.order.nil?
		reward = (self.rewards.select { |r| r["checked"] == true }).first
		return ErrorEnum::REWORD_NOT_SELECTED if reward.nil?
		return ErrorEnum::NOT_LOTTERY_REWARD if reward["type"] != RewardScheme::LOTTERY
		prize = (reward["prizes"].select { |p| p["win"] == true }).first
		return ErrorEnum::NOT_WIN if prize.nil?

		# create lottery order
		order_info.merge!("status" => Order::FROZEN) if self.status == UNDER_REVIEW
		order = Order.create_lottery_order(self.user._id.to_s,
			self.survey._id.to_s,
			prize["prize_id"],
			order_info)
		self.order = order
		return true
	end

	def info_for_sample
		answer_obj = {}
		answer_obj["survey_id"] = self.survey_id.to_s
		answer_obj["survey_title"] = self.survey.title
		answer_obj["is_preview"] = self.is_preview
		answer_obj["rewards"] = self.rewards
		return answer_obj
	end

	def info_for_answer_list_for_sample
		answer_obj = {}
		answer_obj["survey_id"] = self.survey_id.to_s
		answer_obj["survey_title"] = self.survey.title
		answer_obj["order_id"] = self.order._id.to_s
		answer_obj["created_at"] = self.created_at.to_i
		answer_obj["rewards"] = self.rewards
		return answer_obj
	end
end
