require 'error_enum'
module DymanicAttr

    def write_attribute(name, value)
      access = name.to_s
      if attribute_writable?(access)
        _assigning do
          localized = fields[access].try(:localized?)
          typed_value = typed_value_for(access, value)
          unless attributes[access] == typed_value || attribute_changed?(access)
            attribute_will_change!(access)
          end
          if localized
            (attributes[access] ||= {}).merge!(typed_value)
          else
            attributes[access] = typed_value
          end
          typed_value
        end
      end
    end

    def write_attribute_with_judge(name,value)
      if self.has_attribute?(name)
        attribute = name
      else
        attribute = SampleAttribute.where(:name => name).first  
      end
      
      if attribute.present?
        write_attribute_without_judge(name,value)
      else
        return ErrorEnum::SAMPLE_ATTRIBUTE_NOT_EXIST
      end
    end    

    alias_method :write_attribute_without_judge, :write_attribute
    alias_method :write_attribute, :write_attribute_with_judge

end