require 'tool'
class Agent
	include Mongoid::Document
	include Mongoid::Timestamps

	NORMAL = 1
	DELETED = 2

	field :email, :type => String
	field :password, :type => String
	field :name, :type => String
	field :region, :type => Integer
	# 1 for normal, 2 for deleted
	field :status, :type => Integer, default: NORMAL
	field :auth_key, :type => String

	belongs_to :agent_tasks

	default_scope order_by(:created_at.desc)

	scope :normal, where(:status => NORMAL)

	def self.find_by_id(agent_id)
		return self.normal.where(:_id => agent_id).first
	end

	def self.find_by_email(agent_email)
		return self.normal.where(:email => agent_email).first
	end

	def self.find_by_auth_key(auth_key)
		return nil if auth_key.blank?
		agent = self.normal.where(:auth_key => auth_key).first
		return nil if agent.nil?
		return agent
	end

	def self.create_agent(agent)
		return ErrorEnum::AGENT_EXIST if !self.find_by_email(agent["email"]).nil?
		agent["password"] = Encryption.encrypt_password(agent["password"])
		agent= Agent.new(agent)
		agent.save
		return agent
	end

	def update_agent(agent)
		return self.update_attributes(agent)
	end

	def self.search_agent(email, region)
		agents = self.normal
		agents = agents.where(:email => /#{email.to_s}/) if !email.blank?
		if !region.blank?
			agents.select do |e|
				QuillCommon::AddressUtility.satisfy_region_code(e.region, region)
			end
		end
		return agents
	end

	def info
		self["open_agent_task_number"] = AgentTask.where(:agent_id => self._id.to_s, :status.in => [AgentTask::OPEN, AgentTask::AGENT_CLOSED]).length
		return self
	end

	def delete_agent
		self.status = DELETED
		return self.save
	end

	def reset_password(old_password, new_password)
		return ErrorEnum::WRONG_PASSWORD if self.password != Encryption.encrypt_password(old_password)
		self.password = Encryption.encrypt_password(new_password)
		return self.save
	end

	def self.login(email, password)
		encrypted_password = Encryption.encrypt_password(password)
		agent = self.find_by_email(email)
		return ErrorEnum::AGENT_NOT_EXIST if !agent.nil?
		return ErrorEnum::WRONG_PASSWORD if agent.password != encrypted_password
		agent.auth_key = Encryption.encrypt_auth_key("#{agent.email}&#{Time.now.to_i.to_s}")
		agent.save
		return {"auth_key" => agent.auth_key}
	end

	def self.logout(auth_key)
		agent = self.find_by_auth_key(auth_key)
		if !agent.nil?
			agent.auth_key = nil
			agent.save
		end
	end

	def self.login_with_auth_key(auth_key)
		agent = Agent.find_by_auth_key(auth_key)
		return ErrorEnum::AGENT_NOT_EXIST if agent.nil?
		return agent
	end
end