# encoding: utf-8
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
                  :error_message => "未找到符合条件的#{name}"}
      rescue BSON::InvalidObjectId
        retval = {:error_code => ErrorEnum.const_get("INVALID_#{name.upcase}_ID"),
                  :error_message => "#{name}_id格式有误"}
      else
        if block_given?
          retval = yield(retval)
        end
      end
      retval
    end
  end
end