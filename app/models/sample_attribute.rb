require 'data_type'
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
	field :status, :type => Integer, default: 0

	has_many :sample_attribute_questions

	scope :normal, where(status: 1)

	TYPE_ARRAY = [DATA_TYPE::STRING,
		DATA_TYPE::ENUM,
		DATA_TYPE::NUMBER,
		DATA_TYPE::DATE,
		DATA_TYPE::NUMBER_RANGE,
		DATA_TYPE::DATE_RANGE,
		DATA_TYPE::ADDRESS,
		DATA_TYPE::ARRAY]
	ELEMENT_TYPE_ARRAY = [DATA_TYPE::STRING,
		DATA_TYPE::ENUM,
		DATA_TYPE::NUMBER,
		DATA_TYPE::DATE,
		DATA_TYPE::NUMBER_RANGE,
		DATA_TYPE::DATE_RANGE,
		DATA_TYPE::ADDRESS]
	DATE_TYPE_ARRAY = [DATE_TYPE::YEAR,
		DATE_TYPE::YEAR_MONTH,
		DATE_TYPE::YEAR_MONTH_DAY]

	def self.search(name)
		return name.blank? ? self.normal.all : self.normal.where(:name => /.*#{name.to_s}*./)
	end

	def self.create_sample_attribute(sample_attribute)
		retval = self.check_params(sample_attribute)
		return retval if retval != true
		new_sample_attribute = self.new(sample_attribute)
		return new_sample_attribute.save
	end

	def update_sample_attribute
		retval = self.check_params(sample_attribute)
		return retval if retval != true
		return self.update_attributes(sample_attribute)
	end

	def delete
		self.status = 1
		return self.save
	end

	def self.check_params(sample_attribute)
		if !TYPE_ARRAY.include?(sample_attribute["type"])
			return ErrorEnum::WRONG_SAMPLE_ATTRIBUTE_TYPE
		end
		if sample_attribute["type"] == DATA_TYPE::ARRAY && !ELEMENT_TYPE_ARRAY.include?(sample_attribute["type"])
			return ErrorEnum::WRONG_SAMPLE_ATTRIBUTE_TYPE
		end
		if sample_attribute["type"] == DATA_TYPE::DATE || SampleAttribute["type"] == DATA_TYPE::DATE_RANGE
			if !DATE_TYPE_ARRAY.include?(sample_attribute["date_type"])
				return ErrorEnum::WRONG_DATE_TYPE
			end
		end
		return true
	end
end
