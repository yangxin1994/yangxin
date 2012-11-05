module Mongoid
	module FindHelper
		def random(n=1)
			indexes = (0..self.count-1).sort_by{rand}.slice(0,n).collect!
			return indexes.map{ |index| self.skip(index).first }
		end
		
		def find_by_id(id)
			begin
				retval = self.find(id)
			rescue Mongoid::Errors::DocumentNotFound
				retval = {:error_code => ErrorEnum.const_get("#{name.upcase}_NOT_FOUND"),
									:error_message => "#{name} not found!"}
			rescue BSON::InvalidObjectId
				retval = {:error_code => ErrorEnum.const_get("INVALID_#{name.upcase}_ID"),
									:error_message => "invalid #{name} id"}
			else
				if block_given?
					retval = yield(retval)
				end
			end
			retval
		end
	end
end