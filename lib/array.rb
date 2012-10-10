class Array
	def serialize
		ser_ary = []
		self.each do |ele|
			case ele.class
			when Survey
				ser_ary << ele.serialize
			else
				ser_ary << ele
			end
		end
	end

	def mean
		return self.sum / self.length
	end

	def estimate_answer_time
		answer_time = 0
		self.each do |ele|
			answer_time = answer_time + ele.estimate_answer_time if ele.class == Question
		end
	end
end
