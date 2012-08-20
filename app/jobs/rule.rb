module Jobs

	class Condition
		attr_accessor :name, :value 
		def initialize(name, value)
			@name = name
			@value = value
		end
	end

	class Rule
		attr_accessor :survey_id, :condition_type, :conditions, :amount, :fuzzy

		def initialize(survey_id,condition_type, conditions, amount, fuzzy=false)
			if !conditions.instance_of?(Array) || (conditions.size > 0 && !conditions[0].instance_of?(Condition)) then
				raise ArgumentError, "You should set a Array of Condition instances." 
			end
			@survey_id = survey_id.to_s
			@condition_type = condition_type
			@conditions = conditions
			@amount = amount.to_i
			@fuzzy = fuzzy
		end
	end

end