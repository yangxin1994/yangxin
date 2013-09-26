module FindTool
  def self.included(base)
	base.extend(MongoidFinder)
  end

  module MongoidFinder

	def find_by_id(id, &block)
		retval = self.where(:id => id).first
		if retval.present? && block_given?
		  retval = yield(retval)
		end
	end

	def find_by_name(name)
		retval = where(:name => name).first
	end

	def find_by_email_or_mobile(email_mobile)
		retval = any_of({:email => email_mobile},{:mobile => email_mobile}).first
	end  

	def method_missing(method_sym, *arguments, &block)
	  if method_sym.to_s =~ /^find_by_(.*)_or_(.*)/
			any_of({$1.to_sym => arguments.first},{$2.to_sym => arguments.first}).first
	  elsif method_sym.to_s =~ /^find_by_(.*)_and_(.*)$/
			where($1.to_sym => arguments.first).and($2.to_sym => arguments.last).first
	  elsif method_sym.to_s =~ /^find_by_(.*)$/
			where($1.to_sym => arguments.first).first
	  else
		  super
	  end
	end

	def self.respond_to?(method_sym, include_private = false)
	  if method_sym.to_s =~ /^find_by_(.*)$/
			true
	  else
			super
	  end
	end


	# def deprecate(old_method, new_method)
	#   define_method(old_method) do |*args, &block|
	#     warn "Warning: #{old_method}() is deprecated. Use #{new_method}()."
	#     send(new_method, *args, &block)
	#   end
	# end 

  end

end












