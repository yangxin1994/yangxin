require "mongoid/validations/numericality"
module Mongoid
	module ValidationsExt
		def error_code
			@error_code ||= []
			@error_code
		end
		def error_code=(e=[])
			@error_code = e
		end
		class ::String
			def initial_upcase
				self[0] = self[0].upcase
				self
			end
		end
		class SpendValidator < ActiveModel::EachValidator
		  def validate_each(record, attribute, value)
		    spend = case options[:size]
		      when :big then 100000000
		      when :small then 1
		    end
		    #record.error_code = ErrorEnum.const_get("#{record._type}#{attribute}CannotBeBlank")
		    if value > spend
		    	#a = attribute.to_s
		    	#a[0] = a[0].upcase
		    	a = attribute.to_s.initial_upcase
		    	record.error_code << ErrorEnum.const_get("#{record._type}#{a}CounldNotBeBlank")
		    	record.errors[attribute] << "must not exceed #{spend}"
		    end
		  end
		end
######################
	end
end
