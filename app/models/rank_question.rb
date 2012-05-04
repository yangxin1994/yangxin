require 'error_enum'
require 'securerandom'
#Besides the fields that all types questions have, rank questions also have:
# {
#	 "items" : array of items(array),
#	 "is_rand" : whether randomly show blanks(bool)
#	}
#The element in the "items" array has the following structure
# {
#	 "item_id": id of the input
#  "label": label of the item(string),
#  "icon": id of the icon used(string),
#  "icon_num": number of icons(int),
#  "has_input": whether there is a input text field(bool)
#  "has_unknow": whether there is an unknow choice(bool)
#  "desc_ary": array of string to describe the item(array)
# }
class RankQuestion < Question
	field :question_type, :type => String, default: "rank"
	field :items, :type => Array, default: []
	field :is_rand, :type => Boolean, default: false

	ATTR_NAME_ARY = Question::ATTR_NAME_ARY + %w[question_type items rand]
	ITEM_ATTR_ARY = %w[item_id label icon icon_num has_input has_unkonw desc_ary]

	#*description*: serialize the current instance into a question object
	#
	#*params*:
	#
	#*retval*:
	#* the question object
	def serialize
		super(ATTR_NAME_ARY)
	end

	#*description*: update the current question instance, including generate id for new inputs
	#
	#*params*:
	#* the question object
	#
	#*retval*:
	def update_question(question_obj)
		question_obj["items"].each do |item_obj|
			item_obj.delete_if { |k, v| !ITEM_ATTR_ARY.include?(k) }
		end
		super(ATTR_NAME_ARY, question_obj)
		self.items.each do |item|
			item["item_id"] = SecureRandom.uuid if item["item_id"].to_s == ""
		end
		self.save
	end

	#*description*: clone the current question instance, including generate input ids for new instance
	#
	#*params*:
	#
	#*retval*:
	#* the cloned instance
	def clone
		new_inst = super
		new_inst.items.each do |item|
			item["item_id"] = SecureRandom.uuid
		end
		return new_inst
	end

end
