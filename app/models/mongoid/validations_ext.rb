require "mongoid/validations/numericality"
require "mongoid/validations/format_ext" #
require "mongoid/validations/length"
require "mongoid/validations/presence_ext" #
require "mongoid/validations/with"
module Mongoid
	module ValidationsExt
		def error_codes
			@error_codes ||= []
			@error_codes
		end
		def error_code
			@error_codes ||= []
			@error_codes[0]
		end
		def add_error_code(e)
			error_codes << e unless error_codes.include?(e)
		end
		def error_codes=(e=[])
			@error_codes
		end
		def as_retval
			if invalid?
				retval.is_valid = false
				return retval = {:error_code => self.error_codes,
										 		 :error_message => self.errors.messages}
			end
			self
		end
		def is_valid
			valid?
		end
		class ::Hash
			is_valid = false
		end
		class ::String
			def initial_upcase
				self[0] = self[0].upcase
				self
			end
		end
	end
end
