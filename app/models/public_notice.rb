class PublicNotice
	include Mongoid::Document
	include Mongoid::Timestamps

	field :title, :type => String
	field :content, :type => String
	field :attachment, :type => String
	field :public_notice_type, :type => Integer

	belongs_to :user
	
	attr_accessible :title, :content, :attachment, :public_notice_type
	
	# the max of multiple type value => 2**7
	MAX_TYPE = 7
	
	#--
	# instance methods
	#++u
	#
	
	#*description*: verify the public_notice_type value
	#
	#*params*:
	#* type_number: the number of type: 1, 2, 4, ...
	#
	#*retval*:
	#no return
	def public_notice_type=(type_number)
	
		type_number_class = type_number.class
	
		type_number = type_number.to_i
		
		# if type_number is string, to_i will return 0.
		# "0" will raise RangeError, "type1" will raise TypeError
		raise TypeError if type_number_class != Fixnum && type_number == 0
		
		if (type_number % 2 != 0 && type_number !=1) || 
			type_number <= 0 || type_number > 2**MAX_TYPE
			
			raise RangeError
		end
		super
	end

	#--
	# class methods
	#++
	
	class << self

		#*description*: list public_notice s with condition
		#
		#*retval*:
		#public_notice array 
		def find_by_type(type_number=0, value)
			return [] if !type_number.instance_of?(Fixnum)
			public_notices = []
			
			# if type_number = 0
			if type_number == 0 then
				public_notices = PublicNotice.where(title: /.*#{value}.*/) + PublicNotice.where(content: /.*#{value}.*/)
				public_notices.uniq!{|f| f._id.to_s }
				public_notices.sort!{|v1, v2| v2.updated_at <=> v1.updated_at}
				
			else
				# if type_number != 0
				MAX_TYPE.downto(0).each { |element| 
					public_notices_tmp = []
					if type_number / (2**element) == 1 then
						public_notices_tmp = PublicNotice.where(title: /.*#{value}.*/, public_notice_type: 2**element) + PublicNotice.where(content: /.*#{value}.*/, public_notice_type: 2**element)
						public_notices_tmp.uniq!{|f| f._id.to_s }
					end
					type_number = type_number % 2**element
					public_notices = public_notices + public_notices_tmp
				}
			
				public_notices.sort!{|v1, v2| v2.updated_at <=> v1.updated_at} if public_notices.count > 1
			end
			
			return public_notices	
		end
		
	end 
end 
