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
	field :agent_under_review_count, :type => Integer, default: 0
	field :agent_finished_count, :type => Integer, default: 0
	field :agent_reject_count, :type => Integer, default: 0
	field :under_review_count, :type => Integer, default: 0
	field :finished_count, :type => Integer, default: 0
	field :reject_count, :type => Integer, default: 0
	field :auth_key, :type => String

	belongs_to :survey

	default_scope order_by(:created_at.desc)

	scope :normal, where(:status.in => [1, 2])

	def self.find_by_id(agent_task_id)
		return self.normal.where(:_id => agent_task_id).first
	end

	def self.find_by_auth_key(auth_key)
		return nil if auth_key.blank?
		agent_task = AgentTask.normal.where(:auth_key => auth_key).first
		return nil if user.nil?
		# for visitor users, auth_key_expire_time is set as -1
		if user.auth_key_expire_time > Time.now.to_i || user.auth_key_expire_time == -1
			return user
		else
			user.auth_key = nil
			user.save
			return nil
		end
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

	def reset_password(old_password, new_password)
		return ErrorEnum::WRONG_PASSWORD if self.password != Encryption.encrypt_password(old_password)
		self.password = Encryption.encrypt_password(new_password)
		return self.save
	end

	def send_email(callback)
		EmailWorker.perform_async("agent_task", self.email, callback, :agent_task_id => self._id)
		return true
	end


	def self.login(email, password, survey_id)
		survey = Survey.find_by_id(survey_id)
		return ErrorEnum::AGENT_TASK_NOT_EXIST if survey.nil?
		encrypted_password = Encryption.encrypt_password(password)
		agent_task = survey.agent_tasks.where(:email => email, :password => encrypt_password)
		return ErrorEnum::AGENT_TASK_NOT_EXIST if agent_task.nil?
		agent_task.auth_key = Encryption.encrypt_auth_key("#{agent_task._id}&#{Time.now.to_i.to_s}")
		agent_task.save
		return {"auth_key" => agent_task.auth_key}
	end

	def self.logout(auth_key)
		agent_task = AgentTask.find_by_auth_key(auth_key)
		if !agent_task.nil?
			agent_task.auth_key = nil
			agent_task.save
		end
	end

	def self.login_with_auth_key(auth_key)
		agent_task = AgentTask.find_by_auth_key(auth_key)
		return ErrorEnum::AGENT_TASK_NOT_EXIST if agent_task.nil?
		return agent_task
	end
end
