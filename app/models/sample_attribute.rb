require 'data_type'
require 'date_type'
require 'error_enum'
class SampleAttribute
	include Mongoid::Document
	include Mongoid::Timestamps

	field :name, :type => String
	# data type of the sample attribute
	field :type, :type => Integer
	field :element_type, :type => Integer
	field :enum_array, :type => Array
	field :date_type, :type => Integer
	# status of the sample attribute, 1 for normal, 2 for deleted
	field :status, :type => Integer, default: 1

	has_many :questions

	scope :normal, where(status: 1)

	TYPE_ARRAY = [DataType::STRING,
		DataType::ENUM,
		DataType::NUMBER,
		DataType::DATE,
		DataType::NUMBER_RANGE,
		DataType::DATE_RANGE,
		DataType::ADDRESS,
		DataType::ARRAY]
	ELEMENT_TYPE_ARRAY = [DataType::STRING,
		DataType::ENUM,
		DataType::NUMBER,
		DataType::DATE,
		DataType::NUMBER_RANGE,
		DataType::DATE_RANGE,
		DataType::ADDRESS]
	DATE_TYPE_ARRAY = [DateType::YEAR,
		DateType::YEAR_MONTH,
		DateType::YEAR_MONTH_DAY]


	def self.find_by_id(sample_attribute_id)
		return self.normal.where(:_id => sample_attribute_id).first
	end

	def self.search(name)
		return name.blank? ? self.normal.all : self.normal.where(:name => /.*#{name.to_s}*./)
	end

	def self.create_sample_attribute(sample_attribute)
		sample_attribute["type"] = sample_attribute["type"].to_i
		sample_attribute["date_type"] = sample_attribute["date_type"].to_i
		sample_attribute["element_type"] = sample_attribute["element_type"].to_i
		retval = self.check_params(sample_attribute)
		return retval if retval != true
		new_sample_attribute = self.new(sample_attribute)
		return new_sample_attribute.save
	end

	def update_sample_attribute(sample_attribute)
		sample_attribute["type"] = sample_attribute["type"].to_i
		sample_attribute["date_type"] = sample_attribute["date_type"].to_i
		sample_attribute["element_type"] = sample_attribute["element_type"].to_i
		retval = SampleAttribute.check_params(sample_attribute)
		return retval if retval != true
		return self.update_attributes(sample_attribute)
	end

	def bind_question(question_id, relation)
		question = BasicQuestion.find_by_id(question_id)
		return ErrorEnum::QUESTION_NOT_EXIST if question.nil?
		question.sample_attribute = self
		question.sample_attribute_relation = relation
		return question.save
	end

	def delete
		self.status = 2
		return self.save
	end

	def self.check_params(sample_attribute)
		if !TYPE_ARRAY.include?(sample_attribute["type"])
			return ErrorEnum::WRONG_SAMPLE_ATTRIBUTE_TYPE
		end
		if sample_attribute["type"] == DataType::ARRAY && !ELEMENT_TYPE_ARRAY.include?(sample_attribute["element_type"])
			return ErrorEnum::WRONG_SAMPLE_ATTRIBUTE_TYPE
		end
		if sample_attribute["type"] == DataType::DATE || sample_attribute["type"] == DataType::DATE_RANGE
			if !DATE_TYPE_ARRAY.include?(sample_attribute["date_type"])
				return ErrorEnum::WRONG_DATE_TYPE
			end
		end
		return true
	end
end