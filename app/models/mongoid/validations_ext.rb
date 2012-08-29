p require "mongoid/validations/numericality"
p require "mongoid/validations/format" #
p require "mongoid/validations/length"
p require "mongoid/validations/presence_ext" #
p require "mongoid/validations/with"
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
			if invalid?
				return retval = {:error_code => self.error_codes,
										 		 :error_message => self.errors.messages}
			end
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
