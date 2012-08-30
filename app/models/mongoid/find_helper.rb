module Mongoid
  module FindHelper
    def find_by_id(id)
      begin
        retval = self.find(id)
      rescue Mongoid::Errors::DocumentNotFound
        retval = Dummy.new
        retval.add_error_code ErrorEnum.const_get("#{name.upcase}_NOT_FOUND")
        retval.errors.add(name,"not found")
      rescue BSON::InvalidObjectId
        retval = Dummy.new
        retval.add_error_code ErrorEnum.const_get("INVALID_#{name.upcase}_ID")
        retval.errors.add(name," id error")
      else
        retval = yield(retval) if block_given?
      end
      retval
    end
  end
end