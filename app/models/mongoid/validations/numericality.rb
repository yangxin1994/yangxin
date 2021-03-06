module Mongoid
  module Validations
    class NumericalityValidator < ActiveModel::EachValidator
      CHECKS = { :greater_than => :>, :greater_than_or_equal_to => :>=,
                 :equal_to => :==, :less_than => :<, :less_than_or_equal_to => :<=,
                 :odd => :odd?, :even => :even?, :other_than => :!= }.freeze

      RESERVED_OPTIONS = CHECKS.keys + [:only_integer]

      def check_validity!
        keys = CHECKS.keys - [:odd, :even]
        options.slice(*keys).each do |option, value|
          next if value.is_a?(Numeric) || value.is_a?(Proc) || value.is_a?(Symbol)
          raise ArgumentError, ":#{option} must be a number, a symbol or a proc"
        end
      end
      def validate_each(record, attr_name, value)
        before_type_cast = "#{attr_name}_before_type_cast"

        raw_value = record.send(before_type_cast) if record.respond_to?(before_type_cast.to_sym)
        raw_value ||= value
        return if options[:allow_nil] && raw_value.nil?

        unless value = parse_raw_value_as_a_number(raw_value)
          #record.add_error_code ErrorEnum.const_get("#{record.class.name}#{attr_name.to_s.initial_upcase}NotANumber")
          p "#{record.class.name} #{attr_name.to_s} must a number"
          record.add_error_code ErrorEnum.const_get("#{record.class.name.upcase}_#{attr_name.to_s.upcase}_NOT_A_NUNBER")
          record.errors.add(attr_name, :not_a_number, filtered_options(raw_value))
          return
        end

        if options[:only_integer]
          unless value = parse_raw_value_as_an_integer(raw_value)
            # record.add_error_code ErrorEnum.const_get("#{record.class.name.upcase}NotAInteger")
            record.add_error_code ErrorEnum.const_get("#{record.class.name.upcase}_NOT_A_INTEGER")
            record.errors.add(attr_name, :not_an_integer, filtered_options(raw_value))
            return
          end
        end

        options.slice(*CHECKS.keys).each do |option, option_value|
          case option
          when :odd, :even
            unless value.to_i.send(CHECKS[option])
              record.errors.add(attr_name, option, filtered_options(value))
              #record.add_error_code ErrorEnum.const_get("#{record.class.name.upcase}#{attr_name}Not#{option}")
              record.add_error_code ErrorEnum.const_get("#{record.class.name.upcase}_#{attr_name.upcase}_NOT_#{option}")
            end
          else
            option_value = option_value.call(record) if option_value.is_a?(Proc)
            option_value = record.send(option_value) if option_value.is_a?(Symbol)

            unless value.send(CHECKS[option], option_value)
              record.add_error_code ErrorEnum.const_get("#{record._type}#{attr_name}Not#{option}")
              record.errors.add(attr_name, option, filtered_options(value).merge(:count => option_value))
            end
          end
        end
      end

      protected

      def parse_raw_value_as_a_number(raw_value)
        case raw_value
        when /\A0[xX]/
          nil
        else
          begin
            Kernel.Float(raw_value)
          rescue ArgumentError, TypeError
            nil
          end
        end
      end

      def parse_raw_value_as_an_integer(raw_value)
        raw_value.to_i if raw_value.to_s =~ /\A[+-]?\d+\Z/
      end

      def filtered_options(value)
        options.except(*RESERVED_OPTIONS).merge!(:value => value)
      end
    
    end
  end
end