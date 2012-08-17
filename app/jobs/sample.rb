
module Jobs
	class Sample

		attr_accessor :name, :gender, :age, :email

		def initialize(name, gender, age, email)
			@name = name
			@gender = gender
			@age = gender
			@email = email
		end

		class << self 

			def all
				arr = []
				arr << Sample.new("zhangsan", "male", 23, "oopsdata@126.com")
				arr << Sample.new("lisi", "female", 22, "oopsdata@163.com")
				return arr
			end

		end

	end
end