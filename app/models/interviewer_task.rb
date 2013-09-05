require 'error_enum'
require 'quill_common'
class InterviewerTask
	include Mongoid::Document 
	include Mongoid::Timestamps

	field :quota, :type => Hash
	# 0(doing), 1(under review), 2(finished)
	field :status, :type => Integer, default: 0

	belongs_to :survey
	belongs_to :user
	
	has_many :answers


	def self.find_by_id(interviewer_task_id)
		return InterviewerTask.where(_id: interviewer_task_id).first
	end

	def self.create_interviewer_task(survey_id, user_id, quota)
		survey = Survey.find_by_id(survey_id)
		return ErrorEnum::SURVEY_NOT_EXIST if survey.nil?
		interviewer = User.find_by_id(user_id)
		return ErrorEnum::INTERVIEWER_NOT_EXIST if interviewer.nil?
		return ErrorEnum::INTERVIEWER_NOT_EXIST if !interviewer.is_interviewer?
		quota.merge!({"finished_count" => 0,
					"submitted_count" => 0,
					"rejected_count" => 0})
		quota["rules"] ||= []
		quota["rules"]=quota["rules"].map do |r|
			r["amount"] = r["amount"] || 0
			r["finished_count"] = 0
			r["submitted_count"] = 0
			r
		end
		interviewer_task = InterviewerTask.create(quota: quota, user: interviewer, survey: survey)

		# survey.interviewer_tasks << interviewer_task and survey.save
		# interviewer.interviewer_tasks << interviewer_task and interviewer.save
		return interviewer_task
	end

	# *************
	#  
	#  update rule's "amount" which is a num of interviewer, 
	#  then update status
	# 
	#  ******************
	def update_q(quota)
		# quota.merge!({"finished_count" => 0,
		# 			"submitted_count" => 0,
		# 			"rejected_count" => 0})
		# quota["rules"] ||= []
		# quota["rules"].each do |r|
		# 	r["finished_count"] = 0
		# 	r["submitted_count"] = 0
		# end
		retval = update_attributes({
				quota: self.quota.merge(quota)
			})

 		return refresh_quota if retval
 		return false
	end

	# Just update status 
	# 
	def update_status
		# calculate whether quota is satisfied
		finished = true
		under_review = true
		self.quota["rules"].to_a.each do |rule|
			finished = false if rule["finished_count"].to_i < rule["amount"].to_i
			under_review = false if rule["submitted_count"].to_i < rule["amount"].to_i
		end
		if finished
			self.status = 2
		elsif under_review
			self.status = 1
		else
			self.status = 0
		end
		self.save
	end

	# update quota based answers 
	# 
	def refresh_quota
		self.quota["finished_count"] = 0
		self.quota["submitted_count"] = 0
		self.quota["rejected_count"] = 0
		self.quota["rules"].each do |r|
			r["finished_count"] = 0
			r["submitted_count"] = 0
		end
		finished_answers = self.answers.not_preview.finished
		unreviewed_answers = self.answers.not_preview.unreviewed
		rejected_answers = self.answers.not_preview.rejected

		# make stats for the finished answers
		finished_answers.each do |answer|
			self.quota["finished_count"] += 1
			self.quota["submitted_count"] += 1
			self.quota["rules"].each do |rule|
				if answer.satisfy_conditions(rule["conditions"] || [], false)
					rule["finished_count"] += 1
					rule["submitted_count"] += 1
				end
			end
		end

		# make stats for the unreviewed answers
		unreviewed_answers.each do |answer|
			self.quota["submitted_count"] += 1
			self.quota["rules"].each do |rule|
				if answer.satisfy_conditions(rule["conditions"] || [], false)
					rule["submitted_count"] += 1
				end
			end
		end

		# make stats for the rejected answers
		self.quota["rejected_count"] = rejected_answers.length

		# update status
		self.update_status

		return self
	end

	# submit answers
	def submit_answers(answers)
		answers.each do |a|
			# convert the gps or 3g location to a region code
			region = QuillCommon::AddressUtility.find_region_code_by_latlng(*a["location"])
			if a["status"].to_i == 1
				status = Answer::REJECT
			else
				status = self.survey.answer_need_review ? Answer::UNDER_REVIEW : Answer::FINISH
			end
			answer_to_insert = {:interviewer_task_id => self._id,
				:survey_id => self.survey_id,
				:channel => -2,
				:created_at => Time.at(a["created_at"]),
				:finished_at => a["finished_at"].to_i,
				:answer_content => a["answer_content"],
				:attachments => a["attachments"],
				:latitude => a["location"][0].to_s,
				:longitude => a["location"][1].to_s,
				:status => status,
				:reject_type => a["reject_type"].to_i,
				:region => region}
			Answer.create(answer_to_insert)
		end
		self.refresh_quota
		return self
	end
end
