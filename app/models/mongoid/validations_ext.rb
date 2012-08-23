require "mongoid/validations/numericality"
require "mongoid/validations/format"
require "mongoid/validations/length"
require "mongoid/validations/presence"
require "mongoid/validations/with"
module Mongoid
	module ValidationsExt
		def error_codes
			@error_codes ||= []
			@error_codes
		end
		def add_error_code(e)
			error_codes << e unless error_codes.include?(e)
		end
		def error_codes=(e=[])
			@error_codes
		end
		def as_retval
			 return error_codes if invalid?
			 self
		end
		class ::String
			def initial_upcase
				self[0] = self[0].upcase
				self
			end
		end
	end
end
