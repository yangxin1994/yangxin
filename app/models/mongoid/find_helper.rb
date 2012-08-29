module Mongoid
  module FindHelper
    def find_by_id(id)
      begin
        retval = self.find(id)
      rescue Mongoid::Errors::DocumentNotFound
        retval = self.new
        retval.add_error_codes ErrorEnum.const_get("#{name.upcaes}_NOT_FOUND")
      rescue BSON::InvalidObjectId
        retval = self.new
        retval.add_error_codes ErrorEnum.const_get("INVALID_#{name.upcase}_ID")
      else
        retval = yield(retval) if block_given?
      end
      retval
    end
  end
end