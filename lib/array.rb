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
end
