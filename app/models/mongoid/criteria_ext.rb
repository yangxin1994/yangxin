module Mongoid
  module CriteriaExt
    class Mongoid::Criteria
      def present_json(name)
          self.map do |item|
              item.send("present_#{name}")
          end
      end
      # def method_miss(name, *params)
      #   name = name.to_s
      #   p name
      #   if((name =~ /present_/) == 0)
      #       self.map do |item|
      #           item.send("name")
      #       end
      #   end
      #   super(name, *params)
      # end
    end
    def present_attrs(*attrs)
      return @present_attrs = self.attributes if attrs.blank?
      @present_attrs = {}
      attrs.each do |k|
          @present_attrs.store(k, self.attributes[k.to_s])
      end
      @present_attrs
    end

    def present_add(pre_hash={})
      @present_attrs ||= {}
      @present_attrs.merge!(pre_hash)
    end

  end
end
