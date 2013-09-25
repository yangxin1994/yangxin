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

        # def method_miss(name, *params)
        #   name = name.to_s
        #   str_rxp = /\b\w+(?=_attrs\b)/
        #   ret_attrs = {}
        #   if((name =~ str_rxp) == 0)
        #       instance_obj = self.send(name.slice(str_rxp))
        #       params.each do |a|
        #           ret_attrs[a] => instance_obj.send(a)
        #       end
        #       return ret_attrs
        #   end
        #   super(name, *params)
        # end
    end
end