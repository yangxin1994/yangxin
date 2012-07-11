class Faq
	include Mongoid::Document 
	include Mongoid::Timestamps

	# faq_type divide from 1, 2, 4, 8, ..., default 0 includes all types.
	field :faq_type, :type => Integer
	field :question, :type => String
	field :answer, :type => String
					
	belongs_to :user

	attr_accessible :faq_type, :question, :answer
		
	#faq_type max number
	MAX_TYPE = 7
	
	#*description*: verify the faq_type value
	#
	#*params*:
	#* type_number: the number of type: 1, 2, 4, ...
	#
	#*retval*:
	#no return
	def faq_type=(type_number)
	
		type_number_class = type_number.class
		temp = type_number
		type_number = type_number.to_i
		
		# if type_number is string, to_i will return 0.
		# "0" will raise RangeError, "type1" will raise TypeError
		raise TypeError if type_number_class != Fixnum && type_number == 0 && temp.strip !="0"
		
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
		
		#*description*: list faqs with one condition
		#
		#*retval*:
		#faq array 
		def find_by_type(type_number=0, value)
			return [] if !type_number.instance_of?(Fixnum) || type_number <= 0
			faqs = []
			
			# if type_number != 0
			MAX_TYPE.downto(0).each { |element| 
				faqs_tmp = []
				if type_number / (2**element) == 1 then
					faqs_tmp = Faq.where(question: /.*#{value}.*/, faq_type: 2**element) + Faq.where(answer: /.*#{value}.*/, faq_type: 2**element)
					faqs_tmp.uniq!{|f| f._id.to_s }
				end
				type_number = type_number % 2**element
				faqs = faqs + faqs_tmp
			}
			
			faqs.sort!{|v1, v2| v2.updated_at <=> v1.updated_at} if faqs.count > 1
			
			return faqs	
		end
	end
end
