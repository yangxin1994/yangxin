require 'securerandom'

#Define the constrain class
class Constrain

	#Unique id of the constrain. Automatically generated when a constrain is initialized
	attr_reader :constrain_id
	#A string is stored as the constrain condition. It can be an expression which return a boolean value
	attr_reader :constrain_condition
	#A hash, keys of which are restricted to be selected from RESULT_ATTR_ARRAY
	attr_reader :constrain_result

	#array of names of attributes that can be set in constrain_result
	RESULT_ATTR_ARRAY = %w[show, hide, compulsory]

	# initialize a constrain instance, generate its constrain_id
	def initialize
		@constrain_id = SecureRandom.uuid
	end

	# set conditions for a constrain instance, the condition must be string
	def set_constrain_condition(condition)
		raise WrongAugmentError, "constrain condition must be a String" if condition.class != "String"
		@constrain_condition = condition
	end

	# set result for a constrain instance, the result must be a hash, the keys of which be included in RESULT_ATTR_ARRAY
	def set_constrain_result(result_attr)
		result_attr.each { |key, value| @constrain_result[key] = value.to_s if RESULT_ATTR_ARRAY.include?(key) }
	end


	# serialize a constrain object into a hash
	def self.serailize(object)
		return {:constrain_id => @constrain_id, :constrain_condition => @constrain_condition.to_s, :constrain_result => @constrain_result }
	end

	# deserialize a hash into constrain object
	def self.deserailize(object)
		constrain = Constrain.new
		constrain = object[:constrain_id]
		constrain = object[:constrain_condition]
		constrain = object[:constrain_result]
		return constrain
	end

end
