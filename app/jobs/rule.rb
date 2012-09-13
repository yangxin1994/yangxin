module Jobs

	class Condition
		attr_accessor :name, :value, :fuzzy
		def initialize(name, value, fuzzy)
			@name = name
			@value = value
			@fuzzy = fuzzy
		end
		def ==(object_2)
			return true if self.name == object_2.name && self.value == object_2.value && self.fuzzy == object_2.fuzzy
			return false
		end
	end

	class Rule

		MAX_NUMBER = 3

		attr_accessor :survey_id, :conditions, 
					:amount, :time_left, :email_number

		def initialize(survey_id, conditions, amount)
			@survey_id = survey_id.to_s
			@conditions = conditions || []
			@amount = amount.to_i
			survey = Survey.find_by_id(@survey_id)
			@time_left = survey.deadline.to_i - Time.now.to_i if survey
			compute_email_number
		end

		def conditions_names
			names = []
			@conditions.each do |condition|
				names << condition.name
			end
			return names
		end

		def amount_increase(number)
			@amount += number
			compute_email_number
		end

		private

		def compute_email_number
			if @amount <=0 || @time_left < 60
				# if the last one minute, no need to send email.
				# because no one can use less one minute time to answer a survey .
				@email_number = 0 
			else
				# now, this formula does not sure and just simple follows:
				# time_left unit is second.
				tmp = @time_left % (2*60*60) 
				tmp = tmp < 60 ? 60 : tmp
				@email_number = (@amount * 1000 / tmp).to_i

				#but email_number should has max number, we do not like send 1000000
				# now, set max is 1000
				@email_number = @email_number > MAX_NUMBER ? MAX_NUMBER : @email_number
			end
		end
	end
end