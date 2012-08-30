module Mongoid
  module FindHelper
    def find_by_id(id)
      begin
        retval = self.find(id)
      rescue Mongoid::Errors::DocumentNotFound
        retval = {:error_code => ErrorEnum.const_get("#{name.upcase}_NOT_FOUND",
                  :error_message => "#{name} not found!"}
      rescue BSON::InvalidObjectId
        retval = {:error_code => ErrorEnum.const_get("INVALID_#{name.upcase}_ID",
                  :error_message => "invalid #{name} id"}
      else
        retval = yield(retval) if block_given?
      end
      retval
    end
  end
end