module Mongoid
	module FindHelper
		def find_by_id(id)
			begin
				retval = self.find(id)
			rescue Mongoid::Errors::DocumentNotFound
				retval = ErrorEnum.const_get("#{name}NotFound")
			rescue BSON::InvalidObjectId
				retval = ErrorEnum.const_get("Invalid#{name}Id")
			else
				retval = yield(retval) if block_given?
			end
			retval
		end
	end
end