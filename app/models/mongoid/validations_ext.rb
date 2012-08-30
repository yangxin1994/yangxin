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
		def error_message
			self.errors.first[0].to_s + " " + self.errors.first[1]
		end
		def as_retval
			if invalid?
				return retval = {:error_code => self.error_code,
										 		 :error_message => self.error_message}
			end
			self
		end
		def is_valid?
			valid?
		end
		class ::Hash
			def is_valid?
				false
			end
		end
		class ::String
			def initial_upcase
				self[0] = self[0].upcase
				self
			end
		end
	end
end
