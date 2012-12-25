require 'error_enum'
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
		return InterviewerTask.where(id: interviewer_task_id).first
	end

	def self.create_interviewer_task(survey_id, user_id, quota)
		survey = Survey.find_by_id(survey_id)
		return ErrorEnum::SURVEY_NOT_EXIST if survey.nil?
		interviewer = User.find_by_id(user_id)
		return ErrorEnum::INTERVIEWER_NOT_EXIST if user.nil?
		return ErrorEnum::INTERVIEWER_NOT_EXIST if !interviewer.is_interviewer
		quota.merge!({"finished_count" => 0,
					"submitted_count" => 0,
					"rejected_count" => 0})
		quota["rules"] ||= []
		quota["rules"].each do |r|
			r["amount"] = 0
			r["finished_count"] = 0
			r["submitted_count"] = 0
		end
		interviewer_task = InterviewerTask.create(quota: quota)

		survey.interviewer_tasks << interviewer_task
		interviewer.interviewer_task = interviewer_task
		return interviewer_task
	end

	def update(quota)
		quota.merge!({"finished_count" => 0,
					"submitted_count" => 0,
					"rejected_count" => 0})
		quota["rules"] ||= []
		quota["rules"].each do |r|
			r["finished_count"] = 0
			r["submitted_count"] = 0
		end
		self.quota = quota
		save
		return self.update_quota
	end

	def update_quota
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
				if answer.satisfy_conditions(rule["conditions"])
					rule["finished_count"] += 1
					rule["submitted_count"] += 1
				end
			end
		end

		# make stats for the unreviewed answers
		unreviewed_answers.each do |answer|
			self.quota["submitted_count"] += 1
			self.quota["rules"].each do |rule|
				if answer.satisfy_conditions(rule["conditions"])
					rule["submitted_count"] += 1
				end
			end
		end

		# make stats for the rejected answers
		self.quota["rejected_count"] = rejected_answers.length

		# calculate whether quota is satisfied
		finished = true
		under_review = true
		quota["rules"].each do |rule|
			finished = false if rule["finished_count"] < rule["amount"]
			under_review = false if rule["submitted_count"] < rule["amount"]
		end
		if finished
			self.status = 2
		elsif under_review
			self.status = 1
		else
			self.status = 0
		end
		self.save
		return self
	end
end
