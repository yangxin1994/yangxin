module Jobs

	class Condition
		attr_accessor :name, :value 
		def initialize(name, value)
			@name = name
			@value = value
		end

		def to_s
			{name: "#{@name}", value: "#{@value}"}
		end
	end

	class Rule
		attr_accessor :survey_id, :condition_type, :conditions, 
					:amount, :time_left, :email_number, :fuzzy, :sample_ids, 
					:pop_conditions_names

		MaxNumber = 3

		def initialize(survey_id,condition_type, conditions, amount, fuzzy=false)
			if !conditions.instance_of?(Array) || (conditions.size > 0 && !conditions[0].instance_of?(Condition)) then
				raise ArgumentError, "You should set a Array of Condition instances." 
			end
			@survey_id = survey_id.to_s
			@condition_type = condition_type
			@conditions = conditions
			@amount = amount.to_i
			compute_time_left
			compute_email_number
			@fuzzy = fuzzy

			@sample_ids = []
			@pop_conditions_names = []
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

		def to_s
			{survey_id: @survey_id, conditions: JSON.parse(@conditions.to_json), 
					amount: @amount, email_number: @email_number, 
					sample_ids: @sample_ids, pop_conditions_names: @pop_conditions_names}
		end

		def email_number_decrease
			@email_number -= 1
		end

		def amount_increase(number)
			@amount += number
			compute_email_number
		end

		private

		def compute_time_left
			survey = Survey.find_by_id(@survey_id)
			if survey.respond_to?(:deadline) then
				@time_left = (survey.deadline - Time.now).to_i
				@time_left = @time_left < 60 ? 60 : @time_left
			else
				# Is two hours
				@time_left = 2*60*60 #seconds
			end
		end

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
				@email_number = @email_number > MaxNumber ? MaxNumber : @email_number
			end

			# puts "EMNUMBER:::#{@email_number}, amount:::#{@amount}"
		end
	end

end