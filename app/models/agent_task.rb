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
	field :under_review_count, :type => Integer
	field :finished_count, :type => Integer
	field :reject_count, :type => Integer

	belongs_one :survey

	default_scope order_by(:created_at.desc)

	scope :normal, where(:status.in => [1, 2])

	def self.find_by_id(agent_task_id)
		return self.normal.where(:_id => agent_task_id).first
	end

	def self.create_agent_task(agent_task)
		agent_task["password"] = Encryption.encrypt_password(agent_task["password"])
		agent_task = AgentTask.new(agent_task)
		return agent_task.save
	end

	def update_agent_task(agent_task)
		return nself.update_attributes(agent_task)
	end

	def self.search_agent_task(title, status)
		agent_tasks = AgentTask.normal
		status_ary = Tool.convert_int_to_base_arr(params[:status].to_i)
		agent_tasks = agent_tasks.where(:status.in => status_ary)
		agent_tasks = agent_tasks.where(:email => /#{email}/) if !email.blank?
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
