# encoding: utf-8
require 'error_enum'
require 'tool'
require 'securerandom'
#Besides the fields that all types questions have, blank questions also have:
# {
#    "items" : array of input items(array),
#    "is_rand" : whether randomly show blanks(bool)
#   }
#The element in the "inputs" array has the following structure
# {
#  "id": id of the input(string)
#  "label": label of the input(string),
#  "data_type": can be Text, Number, Email, Phone, Address, Time
#  "properties": a hash of properties, for different data type, this input has different properties
# }
#The input with Text data type has the following properties
# {
#  "min_length"
#  "max_length"
#  "has_multiple_line"
#  "size", 1 for small, 2 for middle, 3 for large
# }
#The input with Number data type has the following properties
# {
#  "precision"
#  "min_value"
#  "max_value"
#  "unit"
# }
#The input with phone data type has the following properties
# {
#  "phone_type"
# }
#The input with email data type has the following properties
# {
# }
#The input with address data type has the following properties
# {
#  "format"
# }
#The input with time data type has the following properties
# {
#  "format"
# }
class BlankIssue < Issue

  attr_reader :is_rand, :items, :show_style
  attr_writer :is_rand, :items, :show_style

  ATTR_NAME_ARY = %w[items is_rand show_style]
  ITEM_ATTR_ARY = %w[id content data_type properties]

  DATA_TYPE_ARY = %w[Text Number Phone Email Url Address Time]

  TEXT_PROP_ARY = %w[min_length max_length has_multiple_line size]
  NUMBER_PROP_ARY = %w[precision min_value max_value unit unit_location]
  PHONE_PROP_ARY = %w[phone_type]
  EMAIL_PROP_ARY = %w[]
  URL_PROP_ARY = %w[]
  ADDRESS_PROP_ARY = %w[has_postcode format]
  TIME_PROP_ARY = %w[format min_time max_time]

  def initialize
      @items = []
      @is_rand = false
      @show_style = 0
      1.upto(4) do |input_index|
          input = {}
          input["id"] = Tool.rand_id
          input["content"] = {"text" => "选项#{Tool.convert_digit(input_index)}",
                                                      "image" => [], "audio" => [], "video" => []}
          @items << input
      end
      # the first input's content
      @items[0]["data_type"] = "Text"
      @items[0]["properties"] = {}
      @items[0]["properties"]["min_length"] = 1
      @items[0]["properties"]["max_length"] = 10
      @items[0]["properties"]["has_multiple_line"] = false
      @items[0]["properties"]["size"] = 0
      # the second input's content
      @items[1]["data_type"] = "Number"
      @items[1]["properties"] = {}
      @items[1]["properties"]["precision"] = 0
      @items[1]["properties"]["min_value"] = 0
      @items[1]["properties"]["max_value"] = 100
      @items[1]["properties"]["unit"] = "个"
      @items[1]["properties"]["unit_location"] = 0
      # the third input's content
      @items[2]["data_type"] = "Phone"
      @items[2]["properties"] = {}
      @items[2]["properties"]["phone_type"] = 1
      # the fouth input's content
      @items[3]["data_type"] = "Email"
      @items[3]["properties"] = {}
  end

  #*description*: serialize the current instance into a question object
  #
  #*params*:
  #
  #*retval*:
  #* the question object
  def serialize
      super(ATTR_NAME_ARY)
  end

  def remove_hidden_items(items)
      return if items.blank?
      self.items.delete_if { |input| items["items"].include?(input["id"]) } if !items["items"].blank?
  end

  def estimate_answer_time
      answer_time = 0
      self.items.each do |item|
          case item["data_type"]
          when "Text"
              Issue.create_issue(2, item["properties"]).estimate_answer_time
          when "Number"
              Issue.create_issue(3, item["properties"]).estimate_answer_time
          when "Email"
              Issue.create_issue(4, item["properties"]).estimate_answer_time
          when "Url"
              Issue.create_issue(5, item["properties"]).estimate_answer_time
          when "Phone"
              Issue.create_issue(6, item["properties"]).estimate_answer_time
          when "Time"
              Issue.create_issue(7, item["properties"]).estimate_answer_time
          when "Address"
              Issue.create_issue(8, item["properties"]).estimate_answer_time
          end
      end
      return answer_time
  end

  #*description*: update the current question instance, including generate id for new inputs
  #
  #*params*:
  #* the question object
  #
  #*retval*:
  def update_issue(issue_obj)
      issue_obj["items"] ||= []
      issue_obj["items"].each do |input_obj|
          input_obj.delete_if { |k, v| !ITEM_ATTR_ARY.include?(k) }
          return ErrorEnum::WRONG_DATA_TYPE if !DATA_TYPE_ARY.include?(input_obj["data_type"])
          if input_obj["properties"].class == Hash
              input_obj["properties"].delete_if { |k, v| !BlankIssue.const_get("#{input_obj["data_type"].upcase}_PROP_ARY".to_sym).include?(k) }
          else
              input_obj["properties"] == Hash.new
          end
          case input_obj["data_type"]
          when "Text"
              input_obj["properties"]["min_length"] = input_obj["properties"]["min_length"].to_i if !input_obj["properties"]["min_length"].nil?
              input_obj["properties"]["max_length"] = input_obj["properties"]["max_length"].to_i if !input_obj["properties"]["max_length"].nil?
              input_obj["properties"]["size"] = input_obj["properties"]["size"].to_i if !input_obj["properties"]["size"].nil?
              input_obj["properties"]["has_multiple_line"] = input_obj["properties"]["has_multiple_line"].to_s == "true" if !input_obj["properties"]["has_multiple_line"].nil?
          when "Number"
              input_obj["properties"]["min_value"] = input_obj["properties"]["min_value"].to_i if !input_obj["properties"]["min_value"].nil?
              input_obj["properties"]["max_value"] = input_obj["properties"]["max_value"].to_i if !input_obj["properties"]["max_value"].nil?
              input_obj["properties"]["precision"] = input_obj["properties"]["precision"].to_i if !input_obj["properties"]["precision"].nil?
              input_obj["properties"]["unit_location"] = input_obj["properties"]["unit_location"].to_i if !input_obj["properties"]["unit_location"].nil?
          when "Phone"
              input_obj["properties"]["phone_type"] = input_obj["properties"]["phone_type"].to_i if !input_obj["properties"]["phone_type"].nil?
          when "Address"
              input_obj["properties"]["format"] = input_obj["properties"]["format"].to_i if !input_obj["properties"]["format"].nil?
              input_obj["properties"]["has_postcode"] = input_obj["properties"]["has_postcode"].to_s == "true" if !input_obj["properties"]["has_postcode"].nil?
          when "Time"
              input_obj["properties"]["format"] = input_obj["properties"]["format"].to_i if !input_obj["properties"]["format"].nil?
              input_obj["properties"]["min_time"].map! { |e| e.to_i } if !input_obj["properties"]["min_time"].nil?
              input_obj["properties"]["max_time"].map! { |e| e.to_i } if !input_obj["properties"]["max_time"].nil?
          end
      end
      issue_obj["show_style"] = issue_obj["show_style"].to_i
      issue_obj["is_rand"] = issue_obj["is_rand"].to_s == "true"
      super(ATTR_NAME_ARY, issue_obj)
  end
end
