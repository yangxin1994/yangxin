require "mongoid/validations/numericality"
require "mongoid/validations/format"
require "mongoid/validations/length"
require "mongoid/validations/presence"
require "mongoid/validations/with"
module Mongoid
	module ValidationsExt
		def error_code
			@error_code ||= []
			@error_code
		end
		def error_code=(e=[])
			@error_code = e
		end
		class ::String
			def initial_upcase
				self[0] = self[0].upcase
				self
			end
		end
	end
end
