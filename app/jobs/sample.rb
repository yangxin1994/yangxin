
module Jobs
	class Sample

		attr_accessor :user_id, :conditions, :email, :last_email_time, :meet_surveys

		def initialize(user_id, email, conditions, last_email_time=nil)
			if !conditions.instance_of?(Array) || (conditions.size > 0 && !conditions[0].instance_of?(Condition)) then
				raise ArgumentError, "You should set a Array of Condition instances." 
			end
			@user_id = user_id
			@email = email
			@conditions = conditions
			if last_email_time.nil? && last_email_time.is_a?(Time) then
				@last_email_time = last_email_time
			else
				@last_email_time = Time.new(2012,01,01)
			end
			@meet_surveys = []
		end

		def to_s
			{user_id: @user_id, conditions: JSON.parse(@conditions.to_json), 
					email: @email, last_email_time: @last_email_time, 
					meet_surveys: @meet_surveys}
		end

		def conditions
			@conditions || []
		end	

		def conditions_names
			names = []
			@conditions.each do |condition|
				names << condition.name
			end
			return names
		end

		class << self 

			def all
				arr = []
				conditions = []
				conditions << Condition.new("tp_q_1", "female")
				conditions << Condition.new("tp_q_2", "23")
				arr << Sample.new("1", "oopsdata@126.com",conditions)

				conditions = []
				conditions << Condition.new("tp_q_1", "male")
				conditions << Condition.new("tp_q_2", "24")
				arr << Sample.new("2", "oopsdata@163.com", conditions)

				conditions = []
				conditions << Condition.new("tp_q_1", "male")
				conditions << Condition.new("tp_q_3", "apple")
				arr << Sample.new("3", "oopsdata@qq.com", conditions)

				conditions = []
				conditions << Condition.new("tp_q_3", "apple")
				arr << Sample.new("4", "oopsdata@gmail.com", conditions)

				conditions = []
				conditions << Condition.new("tp_q_1", "male")
				conditions << Condition.new("tp_q_2", "23")
				arr << Sample.new("5", "oopsdata@yahoo.com", conditions)

				conditions = []
				conditions << Condition.new("tp_q_1", "male")
				conditions << Condition.new("tp_q_2", "23")
				conditions << Condition.new("tp_q_3", "pear")
				arr << Sample.new("6", "oopsdata@sogou.com", conditions)

				return arr
			end

		end

	end
end