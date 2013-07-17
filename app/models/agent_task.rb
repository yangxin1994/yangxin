require 'tool'
class AgentTask
	include Mongoid::Document
	include Mongoid::Timestamps

	OPEN = 1
	CLOSED = 2
	AGENT_CLOSED = 4
	DELETED = 8

	# 1 for open tasks, 2 for closed tasks, 4 for agent closed tasks, 8 for deleted tasks
	field :status, :type => Integer, default: OPEN
	field :description, :type => String
	field :count, :type => Integer
	field :agent_under_review_count, :type => Integer, default: 0
	field :agent_finished_count, :type => Integer, default: 0
	field :agent_reject_count, :type => Integer, default: 0
	field :under_review_count, :type => Integer, default: 0
	field :finished_count, :type => Integer, default: 0
	field :reject_count, :type => Integer, default: 0

	belongs_to :survey
	belongs_to :agent
	has_many :answers

	default_scope order_by(:created_at.desc)

	attr_accessible :description, :count

	scope :normal, where(:status.in => [OPEN, CLOSED, AGENT_CLOSED])

	def self.find_by_id(agent_task_id)
		return self.normal.where(:_id => agent_task_id).first
	end

	def self.create_agent_task(agent_task, survey_id, agent_id)
		survey = Survey.find_by_id(survey_id)
		return ErrorEnum::SURVEY_NOT_EXIST if survey.nil?
		agent = Agent.find_by_id(agent_id)
		return ErrorEnum::AGENT_NOT_EXIST if agent.nil?
		agent_task = AgentTask.new(agent_task)
		agent_task.save
		survey.agent_tasks << agent_task
		survey.agent_tasks << agent_task
		return agent_task
	end

	def update_agent_task(agent_task)
		return self.update_attributes(agent_task)
	end

	def self.search_agent_task(agent_id, survey_id)
		agent = Agent.find_by_id(agent_id)
		survey = Survey.find_by_id(survey_id)

		agent_tasks = AgentTask.normal
		agent_tasks = agent_tasks.where(:survey_id => survey_id) if !survey.nil?
		agent_tasks = agent_tasks.where(:agent_id => agent_id) if !agent.nil?

		return agent_tasks
	end

	def info
		self["survey_title"] = self.survey.title
		self["agent_email"] = self.agent.email
		self["agent_name"] = self.agent.name
		return info
	end

	def open
		if self.status == CLOSED
			self.status = OPEN
			return self.save
		else
			return ErrorEnum::WRONG_AGENT_TASK_STATUS
		end
	end

	def close
		if self.status == OPEN || self.status == AGENT_CLOSED
			self.status = CLOSED
			return self.save
		else
			return ErrorEnum::WRONG_AGENT_TASK_STATUS
		end
	end

	def agent_close
		if self.status == OPEN
			self.status = AGENT_CLOSED if self.status == OPEN
			return self.save
		else
			return ErrorEnum::WRONG_AGENT_TASK_STATUS
		end
	end

	def delete_agent_task
		self.status = DELETED
		return self.save
	end
end
