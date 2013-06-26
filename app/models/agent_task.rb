require 'tool'
class AgentTask
	include Mongoid::Document
	include Mongoid::Timestamps

	# 1 for open tasks, 2 for closed tasks, 4 for deleted tasks
	field :status, :type => Integer, default: 1
	field :email, :type => String
	field :password, :type => String
	field :description, :type => String
	field :count, :type => Integer
	field :under_review_count, :type => Integer, default: 0
	field :finished_count, :type => Integer, default: 0
	field :reject_count, :type => Integer, default: 0

	belongs_to :survey

	default_scope order_by(:created_at.desc)

	scope :normal, where(:status.in => [1, 2])

	def self.find_by_id(agent_task_id)
		return self.normal.where(:_id => agent_task_id).first
	end

	def self.create_agent_task(agent_task)
		survey = Survey.find_by_id(agent_task["survey_id"])
		return ErrorEnum::SURVEY_NOT_EXIST if survey.nil?
		agent_task["password"] = Encryption.encrypt_password(agent_task["password"])
		agent_task = AgentTask.new(agent_task)
		agent_task.save
		return agent_task
	end

	def update_agent_task(agent_task)
		return self.update_attributes(agent_task)
	end

	def self.search_agent_task(survey_id, email, status)
		if survey_id.blank?
			agent_tasks = AgentTask.normal
		else
			survey = Survey.find_by_id(survey_id)
			return [] if survey.nil?
			agent_tasks = survey.agent_tasks.normal
		end
		if !status.blank? && status != 0
			status_ary = Tool.convert_int_to_base_arr(status.to_i)
			agent_tasks = agent_tasks.where(:status.in => status_ary)
		end
		agent_tasks = agent_tasks.where(:email => /#{email}/) if !email.blank?
		agent_tasks.each do |a|
			a["survey_title"] = a.survey.try(:title)
		end
		return agent_tasks
	end

	def delete_agent_task
		self.status = 4
		return self.save
	end

	def reset_password(password)
		self.password = Encryption.encrypt_password(password)
		return self.save
	end

	def send_email(callback)
		EmailWorker.perform_async("agent_task", self.email, callback, :agent_task_id => self._id)
		return true
	end
end
